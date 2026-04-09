---
description: Step-by-step guide to setting up a Cardano Stake Pool on Linux — from server setup to block production.
---

# Cardano Stake Pool Guide

A practical, copy-paste-ready guide for setting up and operating a Cardano stake pool on **Ubuntu/Debian Linux**. Maintained by the [StakePool247](https://t.me/StakePool247help) community.

{% hint style="success" %}
**Current version: cardano-node 10.6.2** (Mainnet)

Upgrading from an older release? See the [Upgrade Guide](cardano-node-upgrades/upgrade-to-10.6.2.md).
{% endhint %}

## Quick setup (automated)

Get a relay node installed in minutes with our interactive setup script:

```bash
sudo apt update && sudo apt install -y curl
curl -sL -o setup-relay.sh \
  https://raw.githubusercontent.com/stakepool247/gitbook-stakepool-installation-guide/main/scripts/setup-relay.sh
sudo bash setup-relay.sh
```

The script lets you choose your network, node version, and DB backend via a TUI menu — then handles everything: user creation, packages, binary install, config files, Mithril client, and systemd service.

Prefer to understand each step? Follow the guide below.

---

## What you'll need

### Skills

* Basic Linux command-line experience
* Willingness to keep the node updated when new releases drop
* Security-first mindset (keys, firewall, SSH hardening, backups)

### Hardware — Mainnet

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Servers** | 2 (1 BP + 1 relay) | 3 (1 BP + 2 relays) |
| **OS** | Ubuntu 22.04 / Debian 12+ | Ubuntu 24.04 LTS |
| **CPU** | 2 vCPU | 4 vCPU |
| **RAM** | 8 GB (LMDB backend) | 24 GB (InMemory backend) |
| **Storage** | 300 GB SSD | 350+ GB SSD |
| **Network** | 10 Mbps, low packet loss | 50+ Mbps |

You also need:
* **Offline machine** — for generating and storing cold keys (never connected to internet)
* **Hardware wallet** — Trezor or Ledger (strongly recommended for pledge security)

### Hardware — Testnet (pre-prod)

Same architecture, lighter requirements: 2 vCPU, 16 GB RAM, 150+ GB SSD.

---

## What this guide covers

1. **Server setup** — user creation, swap, packages, firewall
2. **Node installation** — binary install, config files, architecture detection
3. **Relay configuration** — topology, blockchain sync (Mithril), systemd service
4. **Block producer setup** — SPOS scripts, wallet keys, pool keys, registration
5. **Operations** — KES key rotation, upgrades, topology management

---

## Community & support

| | |
|---|---|
| **StakePool247 Support** | [t.me/StakePool247help](https://t.me/StakePool247help) |
| **Cardano SPO Workgroup** | [t.me/CardanoStakePoolWorkgroup](https://t.me/CardanoStakePoolWorkgroup) |
| **Community Tech Support** | [t.me/CardanoCommunityTechSupport](https://t.me/CardanoCommunityTechSupport) |

{% hint style="info" %}
**Open source:** This guide lives on [GitHub](https://github.com/stakepool247/gitbook-stakepool-installation-guide). Found an error or have an improvement? PRs and issues welcome.
{% endhint %}
