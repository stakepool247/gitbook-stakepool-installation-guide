---
description: Install gLiveView for real-time terminal-based monitoring of your Cardano node.
---

# Monitoring with gLiveView

[gLiveView](https://cardano-community.github.io/guild-operators/Scripts/gliveview/) is a terminal-based monitoring tool from the Guild Operators community. It provides a real-time dashboard showing node status, sync progress, peer connections, block propagation, and resource usage.

## Installation

Download gLiveView and its environment config file:

```bash
mkdir -p $HOME/.local/logs
curl -sL -o $HOME/.local/bin/gLiveView.sh \
  https://raw.githubusercontent.com/cardano-community/guild-operators/refs/heads/alpha/scripts/cnode-helper-scripts/gLiveView.sh
curl -sL -o $HOME/.local/bin/env \
  https://raw.githubusercontent.com/cardano-community/guild-operators/refs/heads/alpha/scripts/cnode-helper-scripts/env
chmod 755 $HOME/.local/bin/gLiveView.sh
```

## Configuration

The default `env` file expects paths at `/opt/cardano/cnode`. Update it to match this guide's layout:

```bash
sed -i "s|#CNODE_HOME=.*|CNODE_HOME=\"/home/cardano/cnode\"|" $HOME/.local/bin/env
sed -i "s|#CNODE_PORT=.*|CNODE_PORT=3001|" $HOME/.local/bin/env
sed -i 's|#CONFIG=.*|CONFIG="${CNODE_HOME}/config/config.json"|' $HOME/.local/bin/env
sed -i 's|#SOCKET=.*|SOCKET="${CNODE_HOME}/sockets/node.socket"|' $HOME/.local/bin/env
sed -i 's|#TOPOLOGY=.*|TOPOLOGY="${CNODE_HOME}/config/topology.json"|' $HOME/.local/bin/env
```

Verify the settings:

```bash
grep -E "^(CNODE_HOME|CNODE_PORT|CONFIG|SOCKET|TOPOLOGY)" $HOME/.local/bin/env
```

Expected output:

```
CNODE_HOME="/home/cardano/cnode"
CNODE_PORT=3001
CONFIG="${CNODE_HOME}/config/config.json"
SOCKET="${CNODE_HOME}/sockets/node.socket"
TOPOLOGY="${CNODE_HOME}/config/topology.json"
```

## Usage

With your node running, launch gLiveView:

```bash
gLiveView.sh
```

The dashboard shows:

| Section | Information |
|---------|------------|
| **Header** | Node name, network, uptime, port, version |
| **Epoch** | Current epoch, progress bar, time remaining |
| **Block/Slot** | Current block, slot, tip reference, sync status |
| **Connections** | P2P peer stats, incoming/outgoing connections |
| **Block propagation** | Last block time, propagation percentiles |
| **Resource usage** | CPU, memory, disk I/O, process stats |

{% hint style="info" %}
Press **Q** to quit gLiveView. Press **P** for peer analysis view.
{% endhint %}

## Install on all nodes

Install gLiveView on each of your relay and BP servers — it is a read-only monitoring tool and safe to run on any node.
