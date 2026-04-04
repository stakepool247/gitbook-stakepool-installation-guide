---
description: Quick way to start your Cardano node
---

# Downloading Cardano Blockchain



Synchronizing the Cardano blockchain from scratch will take a long time, depending on your CPU and network connection it could take up to several days.

{% tabs %}
{% tab title="Mithril (Mainnet)" %}
This will auto-detect architecture and fetch the latest Mithril release:

```bash
cd /home/cardano/cnode

# remove old db (if any)
rm -rf db

# detect architecture and fetch latest Mithril version
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then MARCH=x64; elif [ "$ARCH" = "aarch64" ]; then MARCH=arm64; else echo "Unsupported arch: $ARCH"; exit 1; fi

MITHRIL_VERSION=$(curl -s https://api.github.com/repos/input-output-hk/mithril/releases/latest | jq -r '.tag_name')
echo "Installing mithril-client ${MITHRIL_VERSION} (${MARCH})"

curl -L -o mithril.tar.gz \
  "https://github.com/input-output-hk/mithril/releases/download/${MITHRIL_VERSION}/mithril-${MITHRIL_VERSION}-linux-${MARCH}.tar.gz"
tar -xzf mithril.tar.gz
install -m 755 mithril-client $HOME/.local/bin/
rm -f mithril.tar.gz mithril-client mithril-signer mithril-aggregator mithril-relay

# set Mithril environment
export CARDANO_NETWORK=mainnet
export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)
export ANCILLARY_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/ancillary.vkey)

# download the latest snapshot
mithril-client cardano-db download --include-ancillary latest
```

{% hint style="info" %}
`--include-ancillary` downloads the last ledger state and immutable file, which significantly speeds up initial sync. The ancillary data is verified against a separate Ed25519 key.
{% endhint %}
{% endtab %}

{% tab title="Mithril (Testnet / pre-prod)" %}
```bash
cd /home/cardano/cnode

rm -rf db

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then MARCH=x64; elif [ "$ARCH" = "aarch64" ]; then MARCH=arm64; else echo "Unsupported arch: $ARCH"; exit 1; fi

MITHRIL_VERSION=$(curl -s https://api.github.com/repos/input-output-hk/mithril/releases/latest | jq -r '.tag_name')
echo "Installing mithril-client ${MITHRIL_VERSION} (${MARCH})"

curl -L -o mithril.tar.gz \
  "https://github.com/input-output-hk/mithril/releases/download/${MITHRIL_VERSION}/mithril-${MITHRIL_VERSION}-linux-${MARCH}.tar.gz"
tar -xzf mithril.tar.gz
install -m 755 mithril-client $HOME/.local/bin/
rm -f mithril.tar.gz mithril-client mithril-signer mithril-aggregator mithril-relay

export CARDANO_NETWORK=preprod
export AGGREGATOR_ENDPOINT=https://aggregator.release-preprod.api.mithril.network/aggregator
export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/genesis.vkey)
export ANCILLARY_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/ancillary.vkey)

mithril-client cardano-db download --include-ancillary latest
```
{% endtab %}

{% tab title="csnapshots.io" %}
We will use the [cSnapshots.io](https://csnapshots.io/) service to download the latest snapshot for a faster boot.

```
sudo apt update && sudo apt install liblz4-tool jq curl -y
```

downloading and extracting the DB archive (to save space, it will stream the archive and extract it on the fly  -  without storing the downloaded archive itself)

first - let's delete old files:

```
rm -rf /home/cardano/cnode/db 
```

### Downloading the latest blockchain archive

* Mainnet

```
wget -c -O - "https://downloads.csnapshots.io/mainnet/$(wget -qO- https://downloads.csnapshots.io/mainnet/mainnet-db-snapshot.json | jq -r .[].file_name)" | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```

* PreProd (testnet)

```
curl -o - https://downloads.csnapshots.io/snapshots/testnet/$(curl -s https://downloads.csnapshots.io/snapshots/testnet/testnet-db-snapshot.json| jq -r .[].file_name ) | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```

<figure><img src="../.gitbook/assets/CleanShot 2023-05-15 at 19.40.38@2x.jpg" alt=""><figcaption></figcaption></figure>

Wait till it downloads, it could take a while, based on your internet speed. **(Mainnet archive is >100GB; TestNet is <10GB)**


{% endtab %}
{% endtabs %}













