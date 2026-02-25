---
description: Quick way to start your Cardano node
---

# Downloading Cardano Blockchain



Synchronizing the Cardano blockchain from scratch will take a long time, depending on your CPU and network connection it could take up to several days.

{% tabs %}
{% tab title="Mithril" %}
* Mainnet

```

# go to your cnode folder
cd /home/cardano/cnode

# delete current db
rm -rf db

# download mithril 
wget https://github.com/input-output-hk/mithril/releases/download/2430.0/mithril-2430.0-linux-x64.tar.gz

# unzip 
tar -xvzf mithril-2430.0-linux-x64.tar.gz

# Cardano network
export CARDANO_NETWORK=mainnet

# Aggregator API endpoint URL
export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator

# Genesis verification key
export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)

#Download snapshot
mithril-client cardano-db download latest

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













