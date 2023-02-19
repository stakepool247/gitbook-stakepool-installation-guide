---
description: >-
  Let's create a simple configuration for your core/relay node (for core node
  you will need to register keys/certificates which we will touch later)
---

# Cardano Relay Configuration

Let's start by creating a folder structure for our nodes:



```bash
cd 
mkdir -p cnode
cd cnode
mkdir -p config db sockets keys logs scripts  
cd config

```

We will download the latest default configuration and genesis files from here: &#x20;

[https://book.world.dev.cardano.org/environments.html#production-mainnet](https://book.world.dev.cardano.org/environments.html#production-mainnet)

<figure><img src="../.gitbook/assets/CleanShot 2023-02-19 at 10.52.19@2x.jpg" alt=""><figcaption></figcaption></figure>

Let's download them from our server's console**:**

{% tabs %}
{% tab title="Mainnet" %}
```
#downloading
curl -o mainnet-config.json https://book.world.dev.cardano.org/environments/mainnet/config.json
curl -o mainnet-topology.json  https://book.world.dev.cardano.org/environments/mainnet/topology.json
curl -o byron-genesis.json https://book.world.dev.cardano.org/environments/mainnet/byron-genesis.json
curl -o shelley-genesis.json https://book.world.dev.cardano.org/environments/mainnet/shelley-genesis.json
curl -o alonzo-genesis.json https://book.world.dev.cardano.org/environments/mainnet/alonzo-genesis.json

#list downloaded files
ls -al mainnet*

```
{% endtab %}

{% tab title="Testnet (pre-prod)" %}
```
#downloading configs
wget -q -O testnet-config.json https://book.world.dev.cardano.org/environments/preprod/config.json
wget -q -O testnet-alonzo-genesis.json https://book.world.dev.cardano.org/environments/preprod/alonzo-genesis.json
wget -q -O testnet-byron-genesis.json https://book.world.dev.cardano.org/environments/preprod/byron-genesis.json
wget -q -O testnet-shelley-genesis.json https://book.world.dev.cardano.org/environments/preprod/shelley-genesis.json
wget -q -O testnet-topology.json https://book.world.dev.cardano.org/environments/preprod/topology.json

#list downloaded files
ls -al testnet*

```
{% endtab %}
{% endtabs %}

you should now have 5 files in the config folder:

![](<../.gitbook/assets/CleanShot 2021-08-30 at 15.17.52.png>)

We are almost done - I know that you are eager to test what we have done so far :) So let's test and run our **Node on port 3000**

Let's start with the core node:

```bash
cardano-node run --database-path /home/cardano/cnode/db --socket-path /home/cardano/cnode/sockets/node.socket --port 3000 --config /home/cardano/cnode/config/mainnet-config.json  --topology /home/cardano/cnode/config/mainnet-topology.json
```



If you followed the guide, you should see this:

![carano node syncing blocks](<../.gitbook/assets/CleanShot 2021-08-30 at 15.22.00.png>)

![](<../.gitbook/assets/CleanShot 2020-12-03 at 17.55.11@2x.png>)

great! You can now exit this by pressing <mark style="color:blue;">ctrl+c</mark> and continuing to the next chapter!

