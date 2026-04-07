#!/usr/bin/env bash
#
# Cardano Relay Node — Interactive Setup Script
# https://cardano-node-installation.stakepool247.eu/
#
# Sets up a Cardano relay node on a fresh Ubuntu/Debian server.
#
# Usage:
#   sudo bash setup-relay.sh                     # interactive TUI
#   sudo bash setup-relay.sh --non-interactive   # use defaults (mainnet, latest stable, InMemory)
#
# What this does:
#   1. Creates the 'cardano' user
#   2. Configures swap (8GB)
#   3. Installs required system packages
#   4. Creates directory layout + env vars
#   5. Downloads + installs cardano-node binaries
#   6. Downloads network config files + configures DB backend
#   7. Installs Mithril client (for fast blockchain sync)
#   8. Installs gLiveView monitoring tool
#   9. Creates systemd service (not started — you choose when)
#
set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────
NODE_VERSION=""
NODE_PORT=3001
CARDANO_USER="cardano"
NETWORK="mainnet"
DB_BACKEND="V2InMemory"
LMDB_BACKEND="V1LMDB"
INTERACTIVE=true

for arg in "$@"; do
  case "$arg" in
    --preprod)          NETWORK="preprod" ;;
    --mainnet)          NETWORK="mainnet" ;;
    --lmdb)             DB_BACKEND="$LMDB_BACKEND" ;;
    --inmemory)         DB_BACKEND="V2InMemory"
LMDB_BACKEND="V1LMDB" ;;
    --non-interactive)  INTERACTIVE=false ;;
  esac
done

# ─── Helpers ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

step()  { echo -e "\n${BLUE}[$1/${TOTAL_STEPS}] $2${NC}"; }
ok()    { echo -e "  ${GREEN}done${NC} — $1"; }
warn()  { echo -e "  ${YELLOW}$1${NC}"; }
die()   { echo -e "  ${RED}ERROR: $1${NC}"; exit 1; }
TOTAL_STEPS=9

run_as_cardano() { su - "$CARDANO_USER" -c "$1"; }

# ─── Pre-flight ──────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

# Ensure jq and curl are available for the TUI (minimal bootstrap)
if ! command -v jq &>/dev/null || ! command -v curl &>/dev/null; then
  apt-get update -y -qq >/dev/null 2>&1
  apt-get install -y -qq jq curl >/dev/null 2>&1
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH_SUFFIX="linux-amd64"; MARCH="x64" ;;
  aarch64) ARCH_SUFFIX="linux-arm64"; MARCH="arm64" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac

# ─── Fetch available versions ────────────────────────────────────────
echo "Fetching available cardano-node releases..."
RELEASES_JSON=$(curl -s "https://api.github.com/repos/IntersectMBO/cardano-node/releases" | \
  jq -r '[.[:10] | .[] | select(.draft == false) | {tag: .tag_name, pre: .prerelease}]')

LATEST_STABLE=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.pre == false)][0].tag')
LATEST_PRE=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.pre == true)][0].tag // empty')
ALL_STABLE=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.pre == false)][0:4] | .[].tag')

if [[ -z "$NODE_VERSION" ]]; then
  NODE_VERSION="$LATEST_STABLE"
fi

# ─── Interactive TUI ─────────────────────────────────────────────────
if $INTERACTIVE && command -v whiptail &>/dev/null; then

  # 1) Network selection
  NETWORK=$(whiptail --title "Cardano Relay Setup" \
    --menu "Select network:" 12 60 3 \
    "mainnet"  "Production network" \
    "preprod"  "Pre-production testnet" \
    3>&1 1>&2 2>&3) || exit 1

  # 2) Version selection — build menu items
  VERSION_ARGS=()
  for v in $ALL_STABLE; do
    if [[ "$v" == "$LATEST_STABLE" ]]; then
      VERSION_ARGS+=("$v" "latest stable (recommended)")
    else
      VERSION_ARGS+=("$v" "stable")
    fi
  done
  if [[ -n "$LATEST_PRE" ]]; then
    VERSION_ARGS+=("$LATEST_PRE" "pre-release (testnet only)")
  fi

  NODE_VERSION=$(whiptail --title "Cardano Relay Setup" \
    --menu "Select cardano-node version:" 16 60 ${#VERSION_ARGS[@]} \
    "${VERSION_ARGS[@]}" \
    3>&1 1>&2 2>&3) || exit 1

  # 3) DB backend selection
  RAM_MB=$(free -m | awk '/Mem/{print $2}')
  if [[ $RAM_MB -ge 20000 ]]; then
    REC_MEM="recommended for your ${RAM_MB}MB RAM"
    REC_LMDB="uses less RAM but slower"
  else
    REC_MEM="needs 24GB+ RAM (you have ${RAM_MB}MB)"
    REC_LMDB="recommended for your ${RAM_MB}MB RAM"
  fi

  DB_BACKEND=$(whiptail --title "Cardano Relay Setup" \
    --menu "Select ledger DB backend:" 14 70 2 \
    "V2InMemory"  "In-memory  — fast, ${REC_MEM}" \
    "$LMDB_BACKEND" "LMDB on-disk — ${REC_LMDB}" \
    3>&1 1>&2 2>&3) || exit 1

  # 4) Confirmation
  if [[ "$DB_BACKEND" == "V2InMemory" ]]; then
    DB_LABEL="InMemory (24GB+ RAM)"
  else
    DB_LABEL="LMDB OnDisk (8GB+ RAM)"
  fi

  whiptail --title "Confirm Setup" \
    --yesno "Ready to install:\n\n  Network:    ${NETWORK}\n  Version:    cardano-node ${NODE_VERSION}\n  DB Backend: ${DB_LABEL}\n  Arch:       ${ARCH}\n\nProceed?" 15 50 || exit 1
fi

# ─── Build artifact name ─────────────────────────────────────────────
ARTIFACT="cardano-node-${NODE_VERSION}-${ARCH_SUFFIX}.tar.gz"

# ─── Banner ──────────────────────────────────────────────────────────
if [[ "$DB_BACKEND" == "V2InMemory" ]]; then
  DB_LABEL="InMemory"
else
  DB_LABEL="LMDB"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cardano Relay Node Setup                           ║${NC}"
echo -e "${BLUE}║  Node: ${NODE_VERSION}  Network: ${NETWORK}  DB: ${DB_LABEL}$(printf '%*s' $((14 - ${#NETWORK} - ${#DB_LABEL})) '')║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "OS:   $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Arch: $ARCH"
echo "RAM:  $(free -h | awk '/Mem/{print $2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $4}') free"
echo ""

# ─── 1. User ────────────────────────────────────────────────────────
step 1 "Creating user '$CARDANO_USER'"

if id "$CARDANO_USER" &>/dev/null; then
  warn "User '$CARDANO_USER' already exists, skipping"
else
  adduser --disabled-password --gecos "" "$CARDANO_USER"
  ok "User created"
fi
usermod -aG sudo "$CARDANO_USER"

# Allow passwordless sudo for cardano user (needed since we create with --disabled-password)
if [[ ! -f /etc/sudoers.d/cardano ]]; then
  echo "cardano ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cardano
  chmod 440 /etc/sudoers.d/cardano
fi
ok "User '$CARDANO_USER' has sudo access (passwordless)"

# ─── 2. Swap ────────────────────────────────────────────────────────
step 2 "Configuring swap"

if swapon --show | grep -q .; then
  warn "Swap already active ($(free -m | awk '/Swap/{print $2}')MB), skipping"
else
  fallocate -l 8G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
  grep -q 'vm.vfs_cache_pressure' /etc/sysctl.conf || echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
  sysctl -p >/dev/null 2>&1
  ok "8GB swap created and enabled"
fi

# ─── 3. Packages ────────────────────────────────────────────────────
step 3 "Installing system packages"

apt-get update -y -qq >/dev/null
apt-get upgrade -y -qq >/dev/null
apt-get install -y -qq \
  curl wget jq git tmux htop nload unzip xz-utils \
  build-essential pkg-config libffi-dev libgmp-dev libssl-dev \
  libsystemd-dev zlib1g-dev libncurses-dev libtool autoconf automake \
  libsodium-dev >/dev/null 2>&1
ok "All packages installed"

# ─── 4. Directory layout ────────────────────────────────────────────
step 4 "Setting up directory layout and environment"

run_as_cardano '
mkdir -p $HOME/.local/bin
mkdir -p $HOME/cnode
cd $HOME/cnode
mkdir -p config db sockets keys logs scripts

grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" $HOME/.bashrc || \
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $HOME/.bashrc

grep -q "CARDANO_NODE_SOCKET_PATH" $HOME/.bashrc || \
  echo "export CARDANO_NODE_SOCKET_PATH=\"\$HOME/cnode/sockets/node.socket\"" >> $HOME/.bashrc
'
ok "Directories and env vars configured"

# ─── 5. Binaries ────────────────────────────────────────────────────
step 5 "Installing cardano-node ${NODE_VERSION}"

DOWNLOAD_DIR=$(mktemp -d)
cd "$DOWNLOAD_DIR"

echo "  Downloading ${ARTIFACT}..."
curl -sL -o "$ARTIFACT" \
  "https://github.com/IntersectMBO/cardano-node/releases/download/${NODE_VERSION}/${ARTIFACT}"
curl -sL -o checksums.txt \
  "https://github.com/IntersectMBO/cardano-node/releases/download/${NODE_VERSION}/cardano-node-${NODE_VERSION}-sha256sums.txt" 2>/dev/null || true

# Verify checksum if available
if [[ -f checksums.txt ]]; then
  EXPECTED=$(grep "$ARTIFACT" checksums.txt | awk '{print $1}')
  ACTUAL=$(sha256sum "$ARTIFACT" | awk '{print $1}')
  if [[ -n "$EXPECTED" && "$EXPECTED" != "$ACTUAL" ]]; then
    die "Checksum mismatch! Expected: $EXPECTED Got: $ACTUAL"
  fi
fi

tar -xzf "$ARTIFACT"
install -m 755 ./bin/cardano-node ./bin/cardano-cli /home/cardano/.local/bin/
[[ -f ./bin/cardano-submit-api ]] && install -m 755 ./bin/cardano-submit-api /home/cardano/.local/bin/

NODE_VER=$(run_as_cardano '$HOME/.local/bin/cardano-node --version' 2>&1 | head -1)
ok "$NODE_VER"

# ─── 6. Config files + DB backend ──────────────────────────────────
step 6 "Installing network configuration files ($NETWORK, $DB_LABEL)"

CNODE_HOME="/home/cardano/cnode"

if [[ -d "./share/${NETWORK}" ]]; then
  cp "./share/${NETWORK}/"* "$CNODE_HOME/config/"
else
  echo "  Downloading from environments page..."
  for f in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
    curl -sL -o "$CNODE_HOME/config/$f" "https://book.play.dev.cardano.org/environments/${NETWORK}/$f"
  done
fi

# Set the DB backend in config.json
if command -v jq &>/dev/null && [[ -f "$CNODE_HOME/config/config.json" ]]; then
  jq --arg backend "$DB_BACKEND" '.LedgerDB.Backend = $backend' \
    "$CNODE_HOME/config/config.json" > "$CNODE_HOME/config/config.json.tmp" \
    && mv "$CNODE_HOME/config/config.json.tmp" "$CNODE_HOME/config/config.json"
  ok "Config files installed (LedgerDB backend: $DB_BACKEND)"
else
  ok "Config files installed"
fi

chown -R "$CARDANO_USER:$CARDANO_USER" "$CNODE_HOME"

# Clean up download dir
rm -rf "$DOWNLOAD_DIR"

# ─── 7. Mithril client ──────────────────────────────────────────────
step 7 "Installing Mithril client"

MITHRIL_VERSION=$(curl -s https://api.github.com/repos/input-output-hk/mithril/releases/latest | jq -r '.tag_name')
echo "  Latest version: ${MITHRIL_VERSION}"

curl -sL -o /tmp/mithril.tar.gz \
  "https://github.com/input-output-hk/mithril/releases/download/${MITHRIL_VERSION}/mithril-${MITHRIL_VERSION}-linux-${MARCH}.tar.gz"
cd /tmp
tar -xzf mithril.tar.gz
install -m 755 mithril-client /home/cardano/.local/bin/
rm -f mithril.tar.gz mithril-client mithril-signer mithril-aggregator mithril-relay 2>/dev/null || true

MITHRIL_VER=$(run_as_cardano '$HOME/.local/bin/mithril-client --version' 2>&1 | head -1)
ok "$MITHRIL_VER"

# ─── 8. gLiveView monitoring ─────────────────────────────────────────
step 8 "Installing gLiveView monitoring tool"

CNODE_HOME="/home/cardano/cnode"

run_as_cardano '
curl -sL -o $HOME/.local/bin/gLiveView.sh \
  https://raw.githubusercontent.com/cardano-community/guild-operators/refs/heads/alpha/scripts/cnode-helper-scripts/gLiveView.sh
curl -sL -o $HOME/.local/bin/env \
  https://raw.githubusercontent.com/cardano-community/guild-operators/refs/heads/alpha/scripts/cnode-helper-scripts/env
chmod 755 $HOME/.local/bin/gLiveView.sh
'

# Configure env for our paths
sed -i "s|#CNODE_HOME=.*|CNODE_HOME=\"${CNODE_HOME}\"|" /home/cardano/.local/bin/env
sed -i "s|#CNODE_PORT=.*|CNODE_PORT=${NODE_PORT}|" /home/cardano/.local/bin/env
sed -i 's|#CONFIG=.*|CONFIG="${CNODE_HOME}/config/config.json"|' /home/cardano/.local/bin/env
sed -i 's|#SOCKET=.*|SOCKET="${CNODE_HOME}/sockets/node.socket"|' /home/cardano/.local/bin/env
sed -i 's|#TOPOLOGY=.*|TOPOLOGY="${CNODE_HOME}/config/topology.json"|' /home/cardano/.local/bin/env

ok "gLiveView installed (run 'gLiveView.sh' when node is running)"

# ─── 9. Systemd service ─────────────────────────────────────────────
step 9 "Creating systemd service"

cat <<'UNIT' > /etc/systemd/system/cardano-node.service
[Unit]
Description=Cardano Relay Node
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=cardano
Group=cardano
WorkingDirectory=/home/cardano/cnode
ExecStart=/home/cardano/.local/bin/cardano-node run \
    --config /home/cardano/cnode/config/config.json \
    --topology /home/cardano/cnode/config/topology.json \
    --database-path /home/cardano/cnode/db \
    --socket-path /home/cardano/cnode/sockets/node.socket \
    --host-addr 0.0.0.0 \
    --port 3001
KillSignal=SIGINT
RestartKillSignal=SIGINT
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cardano-relay
LimitNOFILE=1048576
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable cardano-node.service >/dev/null
ok "Service created and enabled (not started yet)"

# ─── Mithril environment helper ─────────────────────────────────────
if [[ "$NETWORK" == "mainnet" ]]; then
  MITHRIL_NET="mainnet"
  MITHRIL_AGG="https://aggregator.release-mainnet.api.mithril.network/aggregator"
  MITHRIL_VKEY_PATH="release-mainnet"
  CLI_NET="--mainnet"
else
  MITHRIL_NET="preprod"
  MITHRIL_AGG="https://aggregator.release-preprod.api.mithril.network/aggregator"
  MITHRIL_VKEY_PATH="release-preprod"
  CLI_NET="--testnet-magic 1"
fi

# ─── Done ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Relay node setup complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "  The node is installed but NOT started yet."
echo "  Before starting, you may want to:"
echo ""
echo -e "  ${YELLOW}1) Download blockchain with Mithril${NC} (minutes instead of days):"
echo ""
echo -e "     ${BLUE}su - cardano${NC}"
echo -e "     ${BLUE}cd ~/cnode && rm -rf db${NC}"
echo -e "     ${BLUE}export CARDANO_NETWORK=${MITHRIL_NET}${NC}"
echo -e "     ${BLUE}export AGGREGATOR_ENDPOINT=${MITHRIL_AGG}${NC}"
echo -e "     ${BLUE}export GENESIS_VERIFICATION_KEY=\$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/${MITHRIL_VKEY_PATH}/genesis.vkey)${NC}"
echo -e "     ${BLUE}export ANCILLARY_VERIFICATION_KEY=\$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/${MITHRIL_VKEY_PATH}/ancillary.vkey)${NC}"
echo -e "     ${BLUE}mithril-client cardano-db download --include-ancillary latest${NC}"
echo ""
echo "     Mithril downloads the immutable chain data. On first start, the node"
echo "     will rebuild its ledger state (${DB_BACKEND}) from these files — this"
echo "     may take 10-30 minutes depending on your hardware. No conversion needed."
echo ""
echo -e "  ${YELLOW}2) Edit topology${NC} (add your BP/other relays):"
echo -e "     ${BLUE}nano ~/cnode/config/topology.json${NC}"
echo ""
echo -e "  ${YELLOW}3) Start the node:${NC}"
echo -e "     ${BLUE}sudo systemctl start cardano-node${NC}"
echo -e "     ${BLUE}journalctl -u cardano-node -f${NC}  # watch it come up"
echo ""
echo "  Useful commands:"
echo "    Monitor node:   gLiveView.sh"
echo "    Check logs:     journalctl -u cardano-node -f"
echo "    Check sync:     su - cardano -c 'cardano-cli query tip ${CLI_NET} --socket-path ~/cnode/sockets/node.socket'"
echo "    Stop node:      sudo systemctl stop cardano-node"
echo "    Restart node:   sudo systemctl restart cardano-node"
echo ""
echo "  Configuration:"
echo "    Network:        $NETWORK"
echo "    Node version:   $NODE_VERSION"
echo "    DB backend:     $DB_BACKEND"
echo "    Config dir:     /home/cardano/cnode/config/"
echo ""
echo "  Next steps:"
echo "    - Set up firewall (ufw allow 22/tcp && ufw allow ${NODE_PORT}/tcp && ufw enable)"
echo "    - Repeat this on your second relay server"
echo "    - Follow the Block Producer guide for your BP server"
echo ""
echo -e "  Full guide: ${BLUE}https://cardano-node-installation.stakepool247.eu/${NC}"
echo -e "  Support:    ${BLUE}https://t.me/StakePool247help${NC}"
echo ""
