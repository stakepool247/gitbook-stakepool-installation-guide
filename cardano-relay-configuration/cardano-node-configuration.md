---
description: Configure your Cardano relay node — verify config files, understand topology, and test startup.
---

# Relay configuration

## Understanding relay vs block producer

Your **relay nodes** are publicly reachable and connect to the wider Cardano network. They shield your **block producer** (BP) from direct internet exposure. A typical setup is 1 BP + 2 relays.

The default `topology.json` from the release uses **P2P (peer-to-peer)** networking, which automatically discovers and connects to peers. After you set up your BP, you will add it as a local root peer in your relay's topology. This is covered in the [launching relay](launching-cardano-nodes.md) section.

## Verifying configuration files

If you followed the installation guide, your config files are already in `~/cnode/config/`.

Verify all 6 files are present:

```bash
ls ~/cnode/config/
```

Expected: `alonzo-genesis.json`, `byron-genesis.json`, `config.json`, `conway-genesis.json`, `shelley-genesis.json`, `topology.json`

## Updating configs manually (optional)

To fetch the latest configs after a new node release:

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

## Quick test run

Verify the node starts before configuring the systemd service:

```bash
cardano-node run \
  --database-path /home/cardano/cnode/db \
  --socket-path /home/cardano/cnode/sockets/node.socket \
  --port 3001 \
  --config /home/cardano/cnode/config/config.json \
  --topology /home/cardano/cnode/config/topology.json
```

You should see the node start syncing:

<figure><img src="../.gitbook/assets/terminal-node-sync.png" alt="cardano-node syncing from genesis"><figcaption></figcaption></figure>

Press **Ctrl+C** to stop the node and continue to the next section.
