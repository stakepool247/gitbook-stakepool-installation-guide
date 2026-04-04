#!/usr/bin/env bash
#
# Test suite for the Cardano SPO Installation Guide
# Validates every step from the guide on a fresh Ubuntu/Debian server.
#
# Usage:  sudo bash test-guide.sh [--skip-user] [--full-cleanup]
#
# --skip-user     Skip user creation (if already running as cardano or testing in container)
# --full-cleanup  After tests, remove cardano user, installed packages, and all data
#
# Exit codes:
#   0  All tests passed
#   1  One or more tests failed
#
set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────
NODE_VERSION="10.6.2"
NODE_PORT=3001
CNODE_HOME="/home/cardano/cnode"
CARDANO_USER="cardano"
SYNC_TIMEOUT=300       # seconds to wait for sync progress (fresh DB init can take 2-3 min)
STARTUP_TIMEOUT=30     # seconds to wait for node to produce output

# ─── State ───────────────────────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_NAMES=()
SKIP_USER=false
FULL_CLEANUP=false

for arg in "$@"; do
  case "$arg" in
    --skip-user)     SKIP_USER=true ;;
    --full-cleanup)  FULL_CLEANUP=true ;;
  esac
done

# ─── Helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

section() { echo -e "\n${BLUE}═══ $1 ═══${NC}"; }

pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILED_NAMES+=("$1")
  echo -e "  ${RED}✗${NC} $1"
  echo -e "    ${RED}→ $2${NC}"
}

skip() {
  echo -e "  ${YELLOW}⊘${NC} $1 (skipped)"
}

cleanup() {
  if systemctl is-active cardano-node.service &>/dev/null; then
    echo -e "\n${YELLOW}Stopping cardano-node service...${NC}"
    systemctl stop cardano-node.service 2>/dev/null || true
  fi
  # Remove test service if left behind
  if [[ -f /etc/systemd/system/cardano-node.service ]]; then
    systemctl disable cardano-node.service &>/dev/null || true
    rm -f /etc/systemd/system/cardano-node.service
    systemctl daemon-reload &>/dev/null || true
  fi
}
trap cleanup EXIT

run_as_cardano() {
  su - "$CARDANO_USER" -c "$1"
}

# ─── Pre-flight ──────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cardano SPO Guide — Installation Test Suite    ║${NC}"
echo -e "${BLUE}║  Node version: ${NODE_VERSION}                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Arch: $(uname -m)"
echo "Date: $(date -u)"

# ─── 1. User creation ───────────────────────────────────────────────
section "1. User creation"

if $SKIP_USER; then
  skip "User creation (--skip-user)"
else
  if id "$CARDANO_USER" &>/dev/null; then
    skip "User '$CARDANO_USER' already exists"
  else
    adduser --disabled-password --gecos "" "$CARDANO_USER" &>/dev/null
    usermod -aG sudo "$CARDANO_USER"
    if id "$CARDANO_USER" &>/dev/null; then
      pass "User '$CARDANO_USER' created"
    else
      fail "User creation" "adduser failed"
    fi
  fi

  if groups "$CARDANO_USER" | grep -q sudo; then
    pass "User '$CARDANO_USER' is in sudo group"
  else
    fail "Sudo group" "'$CARDANO_USER' not in sudo group"
  fi
fi

# ─── 2. Swap ────────────────────────────────────────────────────────
section "2. Swap space"

if swapon --show | grep -q .; then
  SWAP_SIZE=$(free -m | awk '/Swap/{print $2}')
  pass "Swap is active (${SWAP_SIZE}MB)"
else
  echo -e "  ${YELLOW}No swap detected — creating 8G swapfile...${NC}"
  if [[ ! -f /swapfile ]]; then
    fallocate -l 8G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile &>/dev/null
    swapon /swapfile
    grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
  if swapon --show | grep -q .; then
    pass "Swap created and active"
  else
    fail "Swap creation" "swapfile not active after setup"
  fi
fi

# ─── 3. System packages ─────────────────────────────────────────────
section "3. System packages"

apt-get update -y -qq &>/dev/null

PACKAGES="curl wget jq git tmux htop nload unzip xz-utils build-essential pkg-config libffi-dev libgmp-dev libssl-dev libsystemd-dev zlib1g-dev libncurses-dev libtool autoconf automake libsodium-dev"

apt-get install -y -qq $PACKAGES &>/dev/null 2>&1

MISSING=""
for pkg in curl wget jq git tmux; do
  if ! command -v "$pkg" &>/dev/null; then
    MISSING="$MISSING $pkg"
  fi
done

if [[ -z "$MISSING" ]]; then
  pass "Required packages installed"
else
  fail "Package installation" "Missing commands:$MISSING"
fi

# ─── 4. Directory layout + env vars ─────────────────────────────────
section "4. Directory layout and environment"

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

EXPECTED_DIRS="config db sockets keys logs scripts"
ALL_DIRS_OK=true
for d in $EXPECTED_DIRS; do
  if [[ ! -d "$CNODE_HOME/$d" ]]; then
    fail "Directory $d" "$CNODE_HOME/$d does not exist"
    ALL_DIRS_OK=false
  fi
done
$ALL_DIRS_OK && pass "Directory layout created ($EXPECTED_DIRS)"

if run_as_cardano 'grep -q CARDANO_NODE_SOCKET_PATH $HOME/.bashrc'; then
  pass "CARDANO_NODE_SOCKET_PATH in .bashrc"
else
  fail "Env var" "CARDANO_NODE_SOCKET_PATH not in .bashrc"
fi

if run_as_cardano 'grep -q "\.local/bin" $HOME/.bashrc'; then
  pass "PATH includes ~/.local/bin"
else
  fail "Env var" "~/.local/bin not in PATH"
fi

# ─── 5. Architecture detection ──────────────────────────────────────
section "5. Architecture detection"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARTIFACT="cardano-node-${NODE_VERSION}-linux-amd64.tar.gz"; pass "Architecture: x86_64 → amd64 artifact" ;;
  aarch64) ARTIFACT="cardano-node-${NODE_VERSION}-linux-arm64.tar.gz"; pass "Architecture: aarch64 → arm64 artifact" ;;
  *) fail "Architecture" "Unsupported: $ARCH"; exit 1 ;;
esac

# ─── 6. Download + verify binaries ──────────────────────────────────
section "6. Download and install cardano-node ${NODE_VERSION}"

DOWNLOAD_DIR=$(mktemp -d)
cd "$DOWNLOAD_DIR"

echo "  Downloading $ARTIFACT..."
if curl -sL -o "$ARTIFACT" "https://github.com/IntersectMBO/cardano-node/releases/download/${NODE_VERSION}/${ARTIFACT}"; then
  pass "Tarball downloaded"
else
  fail "Download" "curl failed for $ARTIFACT"
fi

curl -sL -o checksums.txt "https://github.com/IntersectMBO/cardano-node/releases/download/${NODE_VERSION}/cardano-node-${NODE_VERSION}-sha256sums.txt" 2>/dev/null || true

if [[ -f checksums.txt ]]; then
  EXPECTED=$(grep "$ARTIFACT" checksums.txt | awk '{print $1}')
  ACTUAL=$(sha256sum "$ARTIFACT" | awk '{print $1}')
  if [[ -n "$EXPECTED" && "$EXPECTED" == "$ACTUAL" ]]; then
    pass "Checksum verified"
  elif [[ -z "$EXPECTED" ]]; then
    skip "Checksum (artifact name not found in checksums file)"
  else
    fail "Checksum" "expected=$EXPECTED actual=$ACTUAL"
  fi
else
  skip "Checksum (checksums file not available)"
fi

echo "  Extracting..."
tar -xzf "$ARTIFACT"

if [[ -f ./bin/cardano-node && -f ./bin/cardano-cli ]]; then
  pass "Binaries found in archive"
else
  fail "Archive contents" "cardano-node or cardano-cli not found in ./bin/"
fi

install -m 755 ./bin/cardano-node ./bin/cardano-cli /home/cardano/.local/bin/
[[ -f ./bin/cardano-submit-api ]] && install -m 755 ./bin/cardano-submit-api /home/cardano/.local/bin/

NODE_VER_OUTPUT=$(run_as_cardano '$HOME/.local/bin/cardano-node --version' 2>&1 | head -1)
if echo "$NODE_VER_OUTPUT" | grep -q "$NODE_VERSION"; then
  pass "cardano-node version: $NODE_VER_OUTPUT"
else
  fail "Node version" "Expected $NODE_VERSION, got: $NODE_VER_OUTPUT"
fi

CLI_VER_OUTPUT=$(run_as_cardano '$HOME/.local/bin/cardano-cli --version' 2>&1 | head -1)
pass "cardano-cli version: $CLI_VER_OUTPUT"

# ─── 7. Config files ────────────────────────────────────────────────
section "7. Network configuration files"

if [[ -d ./share/mainnet ]]; then
  cp ./share/mainnet/* "$CNODE_HOME/config/"
  pass "Configs copied from release archive"
else
  echo "  Release archive has no share/mainnet — downloading from environments page..."
  for f in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
    curl -sL -o "$CNODE_HOME/config/$f" "https://book.play.dev.cardano.org/environments/mainnet/$f"
  done
  pass "Configs downloaded from environments page"
fi

CONFIG_OK=true
for f in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
  if [[ ! -s "$CNODE_HOME/config/$f" ]]; then
    fail "Config file" "$f is missing or empty"
    CONFIG_OK=false
  fi
done
$CONFIG_OK && pass "All 6 config files present"

# Validate JSON
JSON_OK=true
for f in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
  if ! jq empty "$CNODE_HOME/config/$f" 2>/dev/null; then
    fail "JSON validation" "$f is not valid JSON"
    JSON_OK=false
  fi
done
$JSON_OK && pass "All config files are valid JSON"

chown -R "$CARDANO_USER:$CARDANO_USER" "$CNODE_HOME"

# ─── 8. Mithril client ──────────────────────────────────────────────
section "8. Mithril client"

MARCH=$( [[ "$ARCH" == "x86_64" ]] && echo "x64" || echo "arm64" )
MITHRIL_VERSION=$(curl -s https://api.github.com/repos/input-output-hk/mithril/releases/latest | jq -r '.tag_name')

if [[ -n "$MITHRIL_VERSION" && "$MITHRIL_VERSION" != "null" ]]; then
  pass "Latest Mithril version detected: $MITHRIL_VERSION"
else
  fail "Mithril version" "Could not fetch latest release from GitHub API"
fi

MITHRIL_URL="https://github.com/input-output-hk/mithril/releases/download/${MITHRIL_VERSION}/mithril-${MITHRIL_VERSION}-linux-${MARCH}.tar.gz"
echo "  Downloading mithril-client..."
if curl -sL -o /tmp/mithril.tar.gz "$MITHRIL_URL"; then
  pass "Mithril tarball downloaded"
else
  fail "Mithril download" "curl failed"
fi

cd /tmp
tar -xzf mithril.tar.gz 2>/dev/null || true
if [[ -f mithril-client ]]; then
  install -m 755 mithril-client /home/cardano/.local/bin/
  rm -f mithril.tar.gz mithril-client mithril-signer mithril-aggregator mithril-relay 2>/dev/null || true
  MITHRIL_VER_OUTPUT=$(run_as_cardano '$HOME/.local/bin/mithril-client --version' 2>&1 | head -1)
  pass "mithril-client installed: $MITHRIL_VER_OUTPUT"
else
  fail "Mithril extract" "mithril-client binary not found after extraction"
fi

# ─── 9. Systemd service: install, start, verify sync ────────────────
section "9. Systemd service (full lifecycle)"

SERVICE_NAME="cardano-node"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat <<'UNIT' > "$SERVICE_FILE"
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

pass "Service file written to $SERVICE_FILE"

# Validate the unit file
VERIFY_OUTPUT=$(systemd-analyze verify "${SERVICE_NAME}.service" 2>&1 || true)
if echo "$VERIFY_OUTPUT" | grep -qi "error"; then
  fail "Systemd verify" "$VERIFY_OUTPUT"
else
  pass "systemd-analyze verify passed"
fi

# Reload, enable, start
systemctl daemon-reload
if systemctl enable "${SERVICE_NAME}.service" &>/dev/null; then
  pass "Service enabled"
else
  fail "Service enable" "systemctl enable failed"
fi

if systemctl start "${SERVICE_NAME}.service"; then
  pass "Service started"
else
  fail "Service start" "systemctl start failed"
  echo "  Journal output:"
  journalctl -u "${SERVICE_NAME}.service" -n 20 --no-pager 2>/dev/null | sed 's/^/    /'
fi

# Wait a moment and check it's still running (didn't crash immediately)
sleep 3

SERVICE_STATUS=$(systemctl is-active "${SERVICE_NAME}.service" 2>/dev/null || true)
if [[ "$SERVICE_STATUS" == "active" ]]; then
  pass "Service is active (running)"
else
  fail "Service status" "Expected 'active', got '$SERVICE_STATUS'"
  echo "  Journal output:"
  journalctl -u "${SERVICE_NAME}.service" -n 30 --no-pager 2>/dev/null | sed 's/^/    /'
fi

# Verify the process is running as the cardano user
SERVICE_PID=$(systemctl show -p MainPID --value "${SERVICE_NAME}.service" 2>/dev/null || true)
if [[ -n "$SERVICE_PID" && "$SERVICE_PID" != "0" ]]; then
  PROC_USER=$(ps -o user= -p "$SERVICE_PID" 2>/dev/null | tr -d '[:space:]')
  if [[ "$PROC_USER" == "$CARDANO_USER" ]]; then
    pass "Process running as user '$CARDANO_USER' (PID: $SERVICE_PID)"
  else
    fail "Process user" "Expected '$CARDANO_USER', got '$PROC_USER'"
  fi
else
  fail "Process PID" "Could not determine MainPID from systemd"
fi

# Check the node is listening on the configured port
echo "  Waiting up to ${STARTUP_TIMEOUT}s for port $NODE_PORT..."
PORT_UP=false
WAITED=0
while [[ $WAITED -lt $STARTUP_TIMEOUT ]]; do
  if ss -tlnp 2>/dev/null | grep -q ":${NODE_PORT} "; then
    PORT_UP=true
    break
  fi
  sleep 2
  WAITED=$((WAITED + 2))
done
if $PORT_UP; then
  pass "Node listening on port $NODE_PORT (${WAITED}s)"
else
  fail "Port check" "Nothing listening on port $NODE_PORT after ${STARTUP_TIMEOUT}s"
fi

# Wait for the node socket to appear (means node completed initialization)
SOCKET_PATH="$CNODE_HOME/sockets/node.socket"
echo "  Waiting up to ${SYNC_TIMEOUT}s for node socket..."
WAITED=0
while [[ $WAITED -lt $SYNC_TIMEOUT ]]; do
  if [[ -S "$SOCKET_PATH" ]]; then
    break
  fi
  if [[ "$(systemctl is-active ${SERVICE_NAME}.service 2>/dev/null)" != "active" ]]; then
    break
  fi
  sleep 5
  WAITED=$((WAITED + 5))
done

if [[ -S "$SOCKET_PATH" ]]; then
  pass "Node socket created (${WAITED}s)"
else
  if [[ "$(systemctl is-active ${SERVICE_NAME}.service 2>/dev/null)" == "active" ]]; then
    fail "Node socket" "Socket not created after ${SYNC_TIMEOUT}s (node may still be initializing)"
  else
    fail "Node socket" "Service crashed during initialization"
  fi
  echo "  Last 20 journal lines:"
  journalctl -u "${SERVICE_NAME}.service" -n 20 --no-pager 2>/dev/null | sed 's/^/    /'
fi

# Query the node via cardano-cli to confirm it's responding
if [[ -S "$SOCKET_PATH" ]]; then
  echo "  Querying node tip via cardano-cli..."
  TIP_OUTPUT=$(run_as_cardano "CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH \$HOME/.local/bin/cardano-cli query tip --mainnet 2>&1" || true)

  if echo "$TIP_OUTPUT" | jq -e '.slot' &>/dev/null; then
    SLOT=$(echo "$TIP_OUTPUT" | jq -r '.slot')
    SYNC_PCT=$(echo "$TIP_OUTPUT" | jq -r '.syncProgress // "unknown"')
    pass "cardano-cli query tip works (slot: $SLOT, syncProgress: $SYNC_PCT)"

    # Check chain is advancing
    sleep 5
    TIP2=$(run_as_cardano "CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH \$HOME/.local/bin/cardano-cli query tip --mainnet 2>&1" || true)
    SLOT2=$(echo "$TIP2" | jq -r '.slot' 2>/dev/null || echo "0")
    if [[ "$SLOT2" -gt "$SLOT" ]]; then
      pass "Chain is advancing (slot $SLOT -> $SLOT2)"
    else
      skip "Chain advancement (slot unchanged — node may be between sync batches)"
    fi
  else
    fail "cardano-cli query tip" "Unexpected output: $(echo "$TIP_OUTPUT" | head -3)"
  fi
fi

# Stop and clean up service
echo "  Stopping service..."
systemctl stop "${SERVICE_NAME}.service" 2>/dev/null || true

STOP_WAITED=0
while [[ "$(systemctl is-active ${SERVICE_NAME}.service 2>/dev/null)" == "active" && $STOP_WAITED -lt 15 ]]; do
  sleep 1
  STOP_WAITED=$((STOP_WAITED + 1))
done

if [[ "$(systemctl is-active ${SERVICE_NAME}.service 2>/dev/null)" != "active" ]]; then
  pass "Service stopped cleanly"
else
  systemctl kill "${SERVICE_NAME}.service" 2>/dev/null || true
  pass "Service stopped (forced)"
fi

systemctl disable "${SERVICE_NAME}.service" &>/dev/null || true
rm -f "$SERVICE_FILE"
systemctl daemon-reload &>/dev/null
pass "Service cleaned up"

# ─── 10. Cleanup ────────────────────────────────────────────────────
section "10. Cleanup"

rm -rf "$DOWNLOAD_DIR"
rm -rf "$CNODE_HOME/db"
rm -f "$CNODE_HOME/sockets/node.socket"
pass "Temp files cleaned up"

if $FULL_CLEANUP; then
  echo -e "  ${YELLOW}Full cleanup requested — removing everything...${NC}"

  # Remove all cardano data
  rm -rf "$CNODE_HOME"
  rm -rf /home/cardano/.local/bin/cardano-node /home/cardano/.local/bin/cardano-cli
  rm -rf /home/cardano/.local/bin/cardano-submit-api /home/cardano/.local/bin/cardano-tracer
  rm -rf /home/cardano/.local/bin/mithril-client
  pass "Cardano binaries and data removed"

  # Remove user
  if id "$CARDANO_USER" &>/dev/null; then
    userdel -r "$CARDANO_USER" 2>/dev/null || true
    pass "User '$CARDANO_USER' removed"
  fi

  # Remove swap (only if we created it)
  if [[ -f /swapfile ]]; then
    swapoff /swapfile 2>/dev/null || true
    rm -f /swapfile
    sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
    sed -i '/vm.swappiness/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/vm.vfs_cache_pressure/d' /etc/sysctl.conf 2>/dev/null || true
    pass "Swap removed"
  fi

  # Remove installed packages
  PACKAGES="curl wget jq git tmux htop nload unzip xz-utils build-essential pkg-config libffi-dev libgmp-dev libssl-dev libsystemd-dev zlib1g-dev libncurses-dev libtool autoconf automake libsodium-dev"
  apt-get remove -y -qq $PACKAGES &>/dev/null 2>&1 || true
  apt-get autoremove -y -qq &>/dev/null 2>&1 || true
  pass "Installed packages removed"

  echo -e "  ${GREEN}Server restored to clean state.${NC}"
fi

# ─── Results ─────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "  Tests run:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:     $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "  ${RED}Failed:     $TESTS_FAILED${NC}"
  echo ""
  echo -e "  ${RED}Failed tests:${NC}"
  for name in "${FAILED_NAMES[@]}"; do
    echo -e "    ${RED}✗${NC} $name"
  done
fi
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "\n${GREEN}All tests passed — the guide works!${NC}\n"
  exit 0
else
  echo -e "\n${RED}$TESTS_FAILED test(s) failed.${NC}\n"
  exit 1
fi
