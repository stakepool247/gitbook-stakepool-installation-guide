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
  libsystemd-dev zlib1g-dev libncursesw5 libtool autoconf automake \
  libsodium-dev
```

## 2) Directory layout and env vars

Run as your `cardano` user:

```bash
mkdir -p $HOME/.local/bin
mkdir -p $HOME/cardano/{db,ipc,logs,files,scripts}

grep -q 'export PATH="$HOME/.local/bin:$PATH"' $HOME/.bashrc || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
source $HOME/.bashrc
```

## 3) Verify architecture

```bash
uname -m
```

Expected values:
- `x86_64` → use linux-amd64 artifact
- `aarch64` → use linux-arm64 artifact

## 4) (Optional) Source-build prerequisites

If you build from source instead of binary artifacts:

- Use **GHC 9.6**
- Use **Cabal 3.8+ or 3.12**
- Use **libblst 0.3.14** (required for 10.6.2 source builds)

For most operators, binary artifacts are preferred for speed and consistency.

## 5) Open firewall ports (example)

Relay node example:

```bash
# SSH
sudo ufw allow 22/tcp
# Cardano relay port (adjust if different)
sudo ufw allow 6000/tcp
sudo ufw enable
sudo ufw status verbose
```

> Keep block producer private and reachable only by your relays/VPN.

## 6) Quick sanity checks

```bash
df -h
free -h
nproc
```

Before syncing mainnet, ensure storage headroom is healthy (300+ GB). 350+ GB is safer for long-term growth.
