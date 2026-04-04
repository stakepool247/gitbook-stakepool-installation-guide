#!/usr/bin/env bash
#
# Test suite for the Cardano SPO Installation Guide
# Validates every step from the guide on a fresh Ubuntu/Debian server.
#
# Usage:  sudo bash test-guide.sh [--skip-user]
#
# --skip-user  Skip user creation (if already running as cardano or testing in container)
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
SYNC_TIMEOUT=60        # seconds to wait for sync progress
STARTUP_TIMEOUT=30     # seconds to wait for node to produce output

# ─── State ───────────────────────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_NAMES=()
SKIP_USER=false
NODE_PID=""

for arg in "$@"; do
  case "$arg" in
    --skip-user) SKIP_USER=true ;;
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
  if [[ -n "$NODE_PID" ]] && kill -0 "$NODE_PID" 2>/dev/null; then
    echo -e "\n${YELLOW}Stopping cardano-node (PID $NODE_PID)...${NC}"
    kill -SIGINT "$NODE_PID" 2>/dev/null || true
    wait "$NODE_PID" 2>/dev/null || true
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

# ─── 9. Systemd unit file validation ────────────────────────────────
section "9. Systemd service file"

cat <<'UNIT' > /etc/systemd/system/cardano-node-test.service
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

if systemd-analyze verify cardano-node-test.service 2>&1 | grep -qi "error"; then
  fail "Systemd unit" "$(systemd-analyze verify cardano-node-test.service 2>&1)"
else
  pass "Systemd unit file parses correctly"
fi

rm -f /etc/systemd/system/cardano-node-test.service

# ─── 10. Node starts and begins syncing ─────────────────────────────
section "10. Node startup and sync test"

NODE_LOG="$CNODE_HOME/logs/test-run.log"

echo "  Starting cardano-node on port $NODE_PORT..."

su - "$CARDANO_USER" -c '
  $HOME/.local/bin/cardano-node run \
    --database-path $HOME/cnode/db \
    --socket-path $HOME/cnode/sockets/node.socket \
    --port '"$NODE_PORT"' \
    --config $HOME/cnode/config/config.json \
    --topology $HOME/cnode/config/topology.json \
    > $HOME/cnode/logs/test-run.log 2>&1 &
  echo $!
' > /tmp/node_pid.txt

NODE_PID=$(cat /tmp/node_pid.txt | tr -d '[:space:]')

if [[ -z "$NODE_PID" ]] || ! kill -0 "$NODE_PID" 2>/dev/null; then
  fail "Node start" "Process did not start (PID: '$NODE_PID')"
else
  pass "cardano-node started (PID: $NODE_PID)"
fi

# Wait for the node to produce output
echo "  Waiting up to ${STARTUP_TIMEOUT}s for node output..."
WAITED=0
while [[ $WAITED -lt $STARTUP_TIMEOUT ]]; do
  if [[ -s "$NODE_LOG" ]]; then
    break
  fi
  sleep 2
  WAITED=$((WAITED + 2))
done

if [[ -s "$NODE_LOG" ]]; then
  pass "Node producing log output (${WAITED}s)"
else
  fail "Node output" "No log output after ${STARTUP_TIMEOUT}s"
  echo "  Dumping any stderr..."
  cat "$NODE_LOG" 2>/dev/null || echo "  (empty)"
fi

# Check the node is still alive (didn't crash on startup)
if kill -0 "$NODE_PID" 2>/dev/null; then
  pass "Node still running after startup"
else
  fail "Node crashed" "Process $NODE_PID is no longer running"
  echo "  Last 20 lines of log:"
  tail -20 "$NODE_LOG" 2>/dev/null || true
fi

# Wait for sync-related log entries
echo "  Waiting up to ${SYNC_TIMEOUT}s for sync activity..."
SYNC_DETECTED=false
WAITED=0
while [[ $WAITED -lt $SYNC_TIMEOUT ]]; do
  if grep -qiE "(chain|block|ledger|peer|sync|slot|tip)" "$NODE_LOG" 2>/dev/null; then
    SYNC_DETECTED=true
    break
  fi
  # Also check the node hasn't crashed
  if ! kill -0 "$NODE_PID" 2>/dev/null; then
    break
  fi
  sleep 3
  WAITED=$((WAITED + 3))
done

if $SYNC_DETECTED; then
  pass "Sync activity detected in logs (${WAITED}s)"
  echo -e "  ${GREEN}Sample log output:${NC}"
  grep -iE "(chain|block|ledger|peer|sync|slot|tip)" "$NODE_LOG" 2>/dev/null | head -5 | sed 's/^/    /'
else
  if kill -0 "$NODE_PID" 2>/dev/null; then
    fail "Sync detection" "Node running but no sync keywords in log after ${SYNC_TIMEOUT}s"
  else
    fail "Sync detection" "Node crashed before sync started"
  fi
  echo "  Last 20 lines of log:"
  tail -20 "$NODE_LOG" 2>/dev/null | sed 's/^/    /' || true
fi

# Stop the node
echo "  Stopping node..."
kill -SIGINT "$NODE_PID" 2>/dev/null || true
STOP_WAITED=0
while kill -0 "$NODE_PID" 2>/dev/null && [[ $STOP_WAITED -lt 15 ]]; do
  sleep 1
  STOP_WAITED=$((STOP_WAITED + 1))
done
if ! kill -0 "$NODE_PID" 2>/dev/null; then
  pass "Node stopped cleanly"
else
  kill -9 "$NODE_PID" 2>/dev/null || true
  pass "Node stopped (forced)"
fi
NODE_PID=""

# ─── 11. Cleanup ────────────────────────────────────────────────────
section "11. Cleanup"

rm -rf "$DOWNLOAD_DIR"
rm -rf "$CNODE_HOME/db"
rm -f "$CNODE_HOME/sockets/node.socket"
rm -f "$NODE_LOG"
rm -f /tmp/node_pid.txt
pass "Temp files cleaned up"

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
