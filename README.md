---
description: Cardano Stake Pool installation guide for dummies (Linux)
---

# Cardano Node 8.1.1



{% hint style="success" %}
The guide is updated for **Mainnet** to work with the **latest release: 8.1.1**

**if you are upgrading from a previous version - check the** [**Upgrade guide**](cardano-node-upgrades/upgrade-to-8.1.1.md) **below.**
{% endhint %}

***

## 📯 Before we start

### Stake pool operator requirements:

* **basic knowledge of Linux administration.**
* **ready to update your node** whenever a new release is coming out. (we will provide you with the necessary information)
* **Ready to learn** new skills :)

## Hardware Requirements for a Stake Pool

#### Mainnet:

* **2-3 Linux servers** (1 block-producing node + 1-2 relay nodes)
  * **OS -** Linux 64-bit (Ubuntu 18.04 LTS, 20.04 LTS; Mint 19.3, 20; Debian 10.3)
  * **2 vCPU -** 1.6GHz or faster ( recommended 4vCPUs)
  * **24 GB** of RAM
  * **120 GB** of disk space (Ideally SSD)
  * **Good internet connection** (at least 10Mbps)
* **Offsite PC** (Home PC/server) for your keys (cold storage)
* **Hardware wallet**: Trezor or Ledger **(HIGHLY recommended)**

#### TestNet (pre-prod):

* **2-3 Linux servers** (1 block-producing node + 1-2 relay nodes)
  * **OS -** Linux 64-bit (Ubuntu 18.04 LTS, 20.04 LTS; Mint 19.3, 20; Debian 10.3)
  * **Min 2 vCPU -** 1.6GHz or faster (2GHz or faster for a stake pool or relay)
  * **Min 16** of RAM (24GB Recommended)
  * **50 GB** of disk space (Ideally SSD)
  * **Good internet connection** (at least 10Mbps)
* **Offsite PC** (Home PC/server) for your keys (cold storage)

\
👉 We are using **Ubuntu 20.04 LTS** as our choice for the OS.\
👉 If you have any questions - join our telegram group: [https://t.me/StakePool247help](https://t.me/StakePool247help) where we have some great **mentors** who are ready to help you!

This guide is based on the official Cardano Official guide and from our experience. We understand that the information flow is HUGE... and therefore we want to have a place where you can find all the necessary information in setting up your own personal **ADA Staking Pool**.

{% hint style="info" %}
To get support, join Cardano Groups:

👉 **StakePool247 Support Group:**\
[https://t.me/StakePool247help](https://t.me/StakePool247help)

👉 **Cardano Shelley & StakePool Best Practice Workgroup** [**https://t.me/CardanoStakePoolWorkgroup**](https://t.me/CardanoStakePoolWorkgroup)&#x20;

👉 **Cardano Community Tech Support** [**https://t.me/CardanoCommunityTechSupport**](https://t.me/CardanoCommunityTechSupport)
{% endhint %}
