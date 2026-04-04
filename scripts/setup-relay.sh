#!/usr/bin/env bash
#
# Cardano Relay Node — Quick Setup Script
# https://cardano-node-installation.stakepool247.eu/
#
# Sets up a Cardano relay node on a fresh Ubuntu/Debian server.
# Run as root:   sudo bash setup-relay.sh
#
# What this does (matches the guide step by step):
#   1. Creates the 'cardano' user
#   2. Configures swap (8GB)
#   3. Installs required system packages
#   4. Creates directory layout + env vars
#   5. Downloads + installs cardano-node binaries
#   6. Downloads network config files
#   7. Installs Mithril client (for fast blockchain sync)
#   8. Creates + starts systemd service
#
# After this script completes, your relay will be syncing.
# Use Mithril to bootstrap the blockchain faster (see guide).
#
set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────
NODE_VERSION="10.6.2"
NODE_PORT=3001
CARDANO_USER="cardano"
NETWORK="mainnet"   # change to "preprod" for testnet

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
TOTAL_STEPS=8

run_as_cardano() { su - "$CARDANO_USER" -c "$1"; }

# ─── Pre-flight ──────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cardano Relay Node Setup                       ║${NC}"
echo -e "${BLUE}║  cardano-node ${NODE_VERSION}  |  Network: ${NETWORK}        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "OS:   $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Arch: $(uname -m)"
echo "RAM:  $(free -h | awk '/Mem/{print $2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $4}') free"
echo ""

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARTIFACT="cardano-node-${NODE_VERSION}-linux-amd64.tar.gz"; MARCH="x64" ;;
  aarch64) ARTIFACT="cardano-node-${NODE_VERSION}-linux-arm64.tar.gz"; MARCH="arm64" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac

# ─── 1. User ────────────────────────────────────────────────────────
step 1 "Creating user '$CARDANO_USER'"

if id "$CARDANO_USER" &>/dev/null; then
  warn "User '$CARDANO_USER' already exists, skipping"
else
  adduser --disabled-password --gecos "" "$CARDANO_USER"
  ok "User created"
fi
usermod -aG sudo "$CARDANO_USER"
ok "User '$CARDANO_USER' is in sudo group"

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
  "https://github.com/IntersectMBO/cardano-node/releases/download/${NODE_VERSION}/cardano-node-${NODE_VERSION}-sha256sums.txt"

# Verify checksum
EXPECTED=$(grep "$ARTIFACT" checksums.txt | awk '{print $1}')
ACTUAL=$(sha256sum "$ARTIFACT" | awk '{print $1}')
if [[ -n "$EXPECTED" && "$EXPECTED" != "$ACTUAL" ]]; then
  die "Checksum mismatch! Expected: $EXPECTED Got: $ACTUAL"
fi

tar -xzf "$ARTIFACT"
install -m 755 ./bin/cardano-node ./bin/cardano-cli /home/cardano/.local/bin/
[[ -f ./bin/cardano-submit-api ]] && install -m 755 ./bin/cardano-submit-api /home/cardano/.local/bin/

NODE_VER=$(run_as_cardano '$HOME/.local/bin/cardano-node --version' 2>&1 | head -1)
ok "$NODE_VER"

# ─── 6. Config files ────────────────────────────────────────────────
step 6 "Installing network configuration files ($NETWORK)"

CNODE_HOME="/home/cardano/cnode"

if [[ -d "./share/${NETWORK}" ]]; then
  cp "./share/${NETWORK}/"* "$CNODE_HOME/config/"
else
  echo "  Downloading from environments page..."
  for f in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
    curl -sL -o "$CNODE_HOME/config/$f" "https://book.play.dev.cardano.org/environments/${NETWORK}/$f"
  done
fi

chown -R "$CARDANO_USER:$CARDANO_USER" "$CNODE_HOME"
ok "Config files installed"

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

# ─── 8. Systemd service ─────────────────────────────────────────────
step 8 "Creating and starting systemd service"

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
systemctl start cardano-node.service
ok "Service created, enabled, and started"

# ─── Done ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Relay node setup complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  Your relay node is now syncing from genesis."
echo "  This will take a long time (days). To speed it up,"
echo "  stop the node and use Mithril to bootstrap:"
echo ""
echo -e "  ${BLUE}sudo systemctl stop cardano-node${NC}"
echo -e "  ${BLUE}su - cardano${NC}"
echo -e "  ${BLUE}# Then follow the Mithril download section in the guide${NC}"
echo ""
echo "  Useful commands:"
echo "    Check logs:     journalctl -u cardano-node -f"
echo "    Check sync:     su - cardano -c 'cardano-cli query tip --${NETWORK}'"
echo "    Stop node:      sudo systemctl stop cardano-node"
echo "    Restart node:   sudo systemctl restart cardano-node"
echo ""
echo "  Next steps:"
echo "    - Set up firewall (ufw allow 22/tcp && ufw allow ${NODE_PORT}/tcp && ufw enable)"
echo "    - Repeat this on your second relay server"
echo "    - Follow the Block Producer guide for your BP server"
echo ""
echo -e "  Full guide: ${BLUE}https://cardano-node-installation.stakepool247.eu/${NC}"
echo -e "  Support:    ${BLUE}https://t.me/StakePool247help${NC}"
echo ""
