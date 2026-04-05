---
description: Prepare your server for Cardano Node 10.6.2 installation.
---

# Prerequisites

Prepare a clean Ubuntu/Debian server for cardano-node **10.6.2**.

{% hint style="info" %}
For most operators, installing official release binaries is the fastest and most reproducible approach. Source builds are only needed for custom patches.
{% endhint %}

## 1) System update and required packages

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  curl wget jq git tmux htop nload unzip xz-utils \
  build-essential pkg-config libffi-dev libgmp-dev libssl-dev \
  libsystemd-dev zlib1g-dev libncurses-dev libtool autoconf automake \
  libsodium-dev
```

## 2) Directory layout and environment variables

Run as your `cardano` user:

```bash
mkdir -p $HOME/.local/bin

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

| Output | Artifact to download |
|--------|---------------------|
| `x86_64` | `linux-amd64` |
| `aarch64` | `linux-arm64` |

{% hint style="info" %}
If architecture and binary mismatch, the node will not start (`Exec format error`). Always verify before downloading.
{% endhint %}

## 4) Source-build prerequisites (optional)

Only needed if building from source instead of release binaries:

| Dependency | Version |
|-----------|---------|
| GHC | 9.6 |
| Cabal | 3.8+ or 3.12 |
| libblst | 0.3.14 |

## 5) Firewall

Check whether UFW is active:

```bash
sudo ufw status verbose
```

For a **production relay**, enable UFW with the required ports:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 3001/tcp
sudo ufw enable
sudo ufw status verbose
```

{% hint style="warning" %}
For a **block producer**, do NOT expose the BP port publicly. Keep your BP reachable only from your relays (private network, WireGuard, or strict IP allowlist).
{% endhint %}

## 6) Sanity checks

```bash
df -h
free -h
nproc
```

Verify at least 300 GB of free storage (350+ GB recommended for long-term growth).

{% hint style="info" %}
Swap can prevent OOM crashes, but it is much slower than real RAM. If your server consistently hits swap, upgrade memory rather than relying on swap as a permanent fix.
{% endhint %}
