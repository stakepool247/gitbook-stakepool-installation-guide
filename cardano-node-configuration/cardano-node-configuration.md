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

We will be download the latest default configuration and genesis files from here:  [https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/index.html](https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/index.html)

![cardano alonzo configuration files](<../.gitbook/assets/CleanShot 2021-08-30 at 15.16.28.png>)

Let's download them from our server's console**:**

{% tabs %}
{% tab title="Mainnet" %}
```
#checking the latest built for configs
export LAST_BUILD=$(curl -s https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/index.html | grep -e "This item has moved" |  sed -e 's/.*build\/\(.*\)\/download.*/\1/')
#downloading configs
wget -q -O mainnet-config.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/mainnet-config.json
wget -q -O mainnet-alonzo-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/mainnet-alonzo-genesis.json
wget -q -O mainnet-byron-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/mainnet-byron-genesis.json
wget -q -O mainnet-shelley-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/mainnet-shelley-genesis.json
wget -q -O mainnet-topology.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/mainnet-topology.json

#list downloaded files
ls -al mainnet*

```
{% endtab %}

{% tab title="Testnet" %}
```
#checking the latest built for configs
export LAST_BUILD=$(curl -s https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/index.html | grep -e "This item has moved" |  sed -e 's/.*build\/\(.*\)\/download.*/\1/')
#downloading configs
wget -q -O testnet-config.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/testnet-config.json
wget -q -O testnet-alonzo-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/testnet-alonzo-genesis.json
wget -q -O testnet-byron-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/testnet-byron-genesis.json
wget -q -O testnet-shelley-genesis.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/testnet-shelley-genesis.json
wget -q -O testnet-topology.json https://hydra.iohk.io/build/${LAST_BUILD}/download/1/testnet-topology.json

#list downloaded files
ls -al testnet*

```
{% endtab %}
{% endtabs %}

you should have now 5 files in the config folder:

![](<../.gitbook/assets/CleanShot 2021-08-30 at 15.17.52.png>)

{% hint style="info" %}
OPTIONAL: By default you have IOG (**relays-new.cardano-mainnet.iohk.io**)  relay in your topology file, let's add one more: **relays.stakepool247.eu**
{% endhint %}

```bash
cat > mainnet-topology.json << EOF
{
  "Producers": [
    {
      "addr": "relays-new.cardano-mainnet.iohk.io",
      "port": 3001,
      "valency": 2
    },
    {
      "addr": "relays.stakepool247.eu",
      "port": 3001,
      "valency": 1
    }
  ]
}
EOF
```

We are almost done - I know that you are eager to test what we have done so far :) So let's test and run our **Node on port 3000**

Let's start with the core node:

```bash
cardano-node run --database-path /home/cardano/cnode/db --socket-path /home/cardano/cnode/sockets/node.socket --port 3000 --config /home/cardano/cnode/config/mainnet-config.json  --topology /home/cardano/cnode/config/mainnet-topology.json
```

{% hint style="warning" %}
Starting from version 1.23.0 the "LiveView" screen has been removed - now we have only text-based output. For more graphical output check the RTView application.
{% endhint %}



If you followed the guide, you should see this:

![carano node syncing blocks](<../.gitbook/assets/CleanShot 2021-08-30 at 15.22.00.png>)

![](<../.gitbook/assets/CleanShot 2020-12-03 at 17.55.11@2x.png>)

great! You can now exit this by pressing <mark style="color:blue;">ctrl+c</mark> and continuing to the next chapter!

