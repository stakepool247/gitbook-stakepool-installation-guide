---
description: Bootstrap the blockchain database using Mithril snapshots or csnapshots.io.
---

# Downloading the blockchain

Syncing from genesis can take days. Use a snapshot service to bootstrap the database in minutes instead.

{% tabs %}
{% tab title="Mithril (Mainnet)" %}
Auto-detects architecture and fetches the latest Mithril release:

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

export CARDANO_NETWORK=mainnet
export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)
export ANCILLARY_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/ancillary.vkey)

mithril-client cardano-db download --include-ancillary latest
```

{% hint style="info" %}
`--include-ancillary` downloads the last ledger state and immutable file, significantly speeding up initial sync. The ancillary data is verified against a separate Ed25519 key.
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
[csnapshots.io](https://csnapshots.io/) provides compressed database archives streamed and extracted on the fly.

Install dependencies:

```bash
sudo apt update && sudo apt install liblz4-tool jq curl -y
```

Remove any existing database:

```bash
rm -rf /home/cardano/cnode/db
```

Download and extract:

**Mainnet** (archive is 100+ GB):

```bash
wget -c -O - "https://downloads.csnapshots.io/mainnet/$(wget -qO- https://downloads.csnapshots.io/mainnet/mainnet-db-snapshot.json | jq -r .[].file_name)" | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```

**Pre-prod testnet** (archive is under 10 GB):

```bash
curl -o - "https://downloads.csnapshots.io/snapshots/testnet/$(curl -s https://downloads.csnapshots.io/snapshots/testnet/testnet-db-snapshot.json | jq -r .[].file_name)" | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```
{% endtab %}
{% endtabs %}
