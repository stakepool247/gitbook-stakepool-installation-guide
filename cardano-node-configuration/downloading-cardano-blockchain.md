---
description: Quick way to start your Cardano node
---

# Downloading Cardano Blockchain

Synchronizing the Cardano blockchain from scratch will take a long time, depending on your CPU and network connection it could take up to several days.

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

{% tabs %}
{% tab title="Mainnet" %}
```
curl -o - https://downloads.csnapshots.io/snapshots/mainnet/$(curl -s https://downloads.csnapshots.io/snapshots/mainnet/mainnet-db-snapshot.json| jq -r .[].file_name ) | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```
{% endtab %}

{% tab title="TestNet" %}
```
curl -o - https://downloads.csnapshots.io/snapshots/testnet/$(curl -s https://downloads.csnapshots.io/snapshots/testnet/testnet-db-snapshot.json| jq -r .[].file_name ) | lz4 -c -d - | tar -x -C /home/cardano/cnode/
```
{% endtab %}
{% endtabs %}

<figure><img src="../.gitbook/assets/CleanShot 2023-05-15 at 19.40.38@2x.jpg" alt=""><figcaption></figcaption></figure>

Wait till it downloads, it could take a while, based on your internet speed. **(Mainnet archive is >60GB; TestNet is <1GB)**

