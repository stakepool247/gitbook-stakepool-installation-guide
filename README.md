---
description: Cardano Stake Pool installation guide for dummies (Linux)
---

# Cardano Node 10.6.2

{% hint style="success" %}
The guide is updated for **Mainnet** with **cardano-node 10.6.2**.

If you are upgrading from an older release, use the upgrade section and validate configs before restarting production nodes.
{% endhint %}

***

## 📯 Before we start

### Stake pool operator requirements

* Basic Linux administration skills
* Be ready to update the node whenever a new release is published
* Keep security + backups as a first-class concern (keys, firewall, SSH hardening)

## Hardware requirements for a stake pool

#### Mainnet (recommended)

* **2–3 Linux servers** (1 block producer + 1–2 relays)
  * **OS:** Ubuntu 22.04/24.04 LTS or Debian 12+
  * **CPU:** 2+ vCPU (4 vCPU preferred)
  * **RAM:** 24 GB (for InMemory backend) / 8+ GB (for OnDisk backend)
  * **Storage:** 300 GB minimum (350+ GB recommended, SSD)
  * **Network:** stable 10+ Mbps, low packet loss
* **Offline machine** for cold keys
* **Hardware wallet** (strongly recommended)

#### Testnet / pre-prod

* Similar setup with lower pressure, but keep at least:
  * 2 vCPU
  * 16 GB RAM recommended
  * 150+ GB SSD

👉 This guide uses **Ubuntu 24.04 LTS** examples.  
👉 Support group: [https://t.me/StakePool247help](https://t.me/StakePool247help)

This guide is based on official Cardano docs + operator best practice, with practical commands and safer defaults.

{% hint style="info" %}
Useful communities:

👉 **StakePool247 Support Group:**  
[https://t.me/StakePool247help](https://t.me/StakePool247help)

👉 **Cardano StakePool Workgroup:**  
[https://t.me/CardanoStakePoolWorkgroup](https://t.me/CardanoStakePoolWorkgroup)

👉 **Cardano Community Tech Support:**  
[https://t.me/CardanoCommunityTechSupport](https://t.me/CardanoCommunityTechSupport)
{% endhint %}
