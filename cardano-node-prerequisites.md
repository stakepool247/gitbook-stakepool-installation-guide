---
description: Prepare your server for Cardano Node 10.6.2 installation.
---

# Getting ready to install Cardano Node (v10.6.2)

This page prepares a clean Ubuntu/Debian server for cardano-node **10.6.2**.

> Recommended approach for operators: install official release binaries first (fast, reproducible), then move to source builds only if you need custom patches.

## 1) System update + required packages

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  curl wget jq git tmux htop nload unzip xz-utils \
  build-essential pkg-config libffi-dev libgmp-dev libssl-dev \
  libsystemd-dev zlib1g-dev libncurses-dev libtool autoconf automake \
  libsodium-dev
```

## 2) Directory layout and env vars

Run as your `cardano` user:

```bash
mkdir -p $HOME/.local/bin

# canonical cnode layout (kept for compatibility with existing users)
cd $HOME
mkdir -p cnode
cd cnode
mkdir -p config db sockets keys logs scripts

grep -q 'export PATH="$HOME/.local/bin:$PATH"' $HOME/.bashrc || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc

grep -q 'CARDANO_NODE_SOCKET_PATH' $HOME/.bashrc || \
  echo 'export CARDANO_NODE_SOCKET_PATH="$HOME/cnode/sockets/node.socket"' >> $HOME/.bashrc

source $HOME/.bashrc
```

## 3) Verify architecture

```bash
uname -m
```

Expected values:
- `x86_64` → use linux-amd64 artifact
- `aarch64` → use linux-arm64 artifact

{% hint style="info" %}
Why this matters: if architecture and binary mismatch, the node will not start (`Exec format error`). Always verify `uname -m` before downloading.
{% endhint %}

## 4) (Optional) Source-build prerequisites

If you build from source instead of binary artifacts:

- Use **GHC 9.6**
- Use **Cabal 3.8+ or 3.12**
- Use **libblst 0.3.14** (required for 10.6.2 source builds)

For most operators, binary artifacts are preferred for speed and consistency.

## 5) Firewall (recommended for production, optional for lab testing)

By default, many Ubuntu/Debian servers have UFW **inactive**. Check first:

```bash
sudo ufw status verbose
```

If you are doing a quick local/lab test, you can keep firewall setup for later.

If this is a production relay, enable UFW now with only required ports:

```bash
# allow SSH (change if your SSH port is custom)
sudo ufw allow 22/tcp
# allow relay port (default in this guide: 3001)
sudo ufw allow 3001/tcp

sudo ufw enable
sudo ufw status verbose
```

{% hint style="warning" %}
For a **block producer**, do NOT expose BP port publicly. Keep BP reachable only from your relays (private network, WireGuard, or strict IP allowlist).
{% endhint %}

## 6) Quick sanity checks

```bash
df -h
free -h
nproc
```

Before syncing mainnet, ensure storage headroom is healthy (300+ GB). 350+ GB is safer for long-term growth.

{% hint style="info" %}
If RAM pressure is high, swap can prevent crashes, but swap is much slower than real RAM. If you constantly hit swap, upgrade memory instead of relying on swap as a permanent fix.
{% endhint %}
