---
description: >-
  Let's create a simple configuration for your core/relay node (for core node
  you will need to register keys/certificates which we will touch later)
---

# Cardano Relay Configuration

{% hint style="info" %}
If you followed the installation guide, your config files are already in `~/cnode/config/`. This section covers relay-specific adjustments. If you need to re-download configs, see the tabs below.
{% endhint %}

### Updating configuration files (optional)

If you need to fetch the latest configs manually (e.g. after a new node release):

{% tabs %}
{% tab title="Mainnet" %}
```bash
cd ~/cnode/config

curl -o config.json https://book.play.dev.cardano.org/environments/mainnet/config.json
curl -o topology.json https://book.play.dev.cardano.org/environments/mainnet/topology.json
curl -o byron-genesis.json https://book.play.dev.cardano.org/environments/mainnet/byron-genesis.json
curl -o shelley-genesis.json https://book.play.dev.cardano.org/environments/mainnet/shelley-genesis.json
curl -o alonzo-genesis.json https://book.play.dev.cardano.org/environments/mainnet/alonzo-genesis.json
curl -o conway-genesis.json https://book.play.dev.cardano.org/environments/mainnet/conway-genesis.json

ls -al
```
{% endtab %}

{% tab title="Testnet (pre-prod)" %}
```bash
cd ~/cnode/config

curl -o config.json https://book.play.dev.cardano.org/environments/preprod/config.json
curl -o topology.json https://book.play.dev.cardano.org/environments/preprod/topology.json
curl -o byron-genesis.json https://book.play.dev.cardano.org/environments/preprod/byron-genesis.json
curl -o shelley-genesis.json https://book.play.dev.cardano.org/environments/preprod/shelley-genesis.json
curl -o alonzo-genesis.json https://book.play.dev.cardano.org/environments/preprod/alonzo-genesis.json
curl -o conway-genesis.json https://book.play.dev.cardano.org/environments/preprod/conway-genesis.json

ls -al
```
{% endtab %}
{% endtabs %}

You should have 6 files in the config folder: `config.json`, `topology.json`, `byron-genesis.json`, `shelley-genesis.json`, `alonzo-genesis.json`, `conway-genesis.json`.

### Quick test run

Let's verify the node starts correctly before setting up the systemd service:

```bash
cardano-node run \
  --database-path /home/cardano/cnode/db \
  --socket-path /home/cardano/cnode/sockets/node.socket \
  --port 3001 \
  --config /home/cardano/cnode/config/config.json \
  --topology /home/cardano/cnode/config/topology.json
```

If you followed the guide, you should see the node start syncing:

<figure><img src="../.gitbook/assets/CleanShot 2023-05-15 at 19.33.13@2x.jpg" alt=""><figcaption></figcaption></figure>

Press <mark style="color:blue;">ctrl+c</mark> to stop and continue to the next chapter.

