---
description: >-
  As the Cardano Node management is getting more complicated I would recommend
  using StakePool Operator Scripts (SPOS) (also known as Martin's Scripts -
  ATADA Stake pool owner).
---

# Installing the StakePool Operator Scripts (SPOS)

{% hint style="danger" %}
You have to install these scripts  on your SECURE Server/Workstation/Virtual PC which is running Ubuntu and where you have successfully installed the Cardano Node

We will be creating keys for your pledge wallet as well as keys for your StakePool. \
ANYONE who has access to these keys will have FULL CONTROL over your wallets and Stake Pool. **Never put these keys on your online server.**
{% endhint %}

{% hint style="info" %}
For better security SPOS scripts allow you to generate all the keys and certificates on a PC that is offline (air-gapped) as well as using Hardware Wallets (this is not covered here)
{% endhint %}

Let's start by downloading packages that are used by the scripts

```
sudo apt update -y 
sudo apt install -y curl bc jq 
```

Let us now download the scripts:

```
cd 
mkdir -p git
cd git

# just in case we already have an older folder there - let's remove it
rm -rf scripts

# cloning the code from github
git clone https://github.com/gitmachtl/scripts

cd scripts
ls -al

```

as a result, you should see this

<figure><img src="../.gitbook/assets/CleanShot 2023-05-15 at 20.18.03@2x.jpg" alt=""><figcaption></figcaption></figure>

let's copy the scripts to our bin folder, so we can call them from anywhere:

{% tabs %}
{% tab title="Mainnet" %}
```
cp cardano/mainnet/* ~/.local/bin/
cd ~/.local/bin/
```

Now we have to do a simple configuration so the script knows where to find files and the socket. We will place the configuration file in our home directory, so you don't have to edit files again when next time you decide to upgrade the scripts.

```
cat <<EOF > ~/.common.inc
socket="/home/cardano/cnode/sockets/node.socket"

genesisfile="/home/cardano/cnode/config/shelley-genesis.json"           #Shelley-Genesis path
genesisfile_byron="/home/cardano/cnode/config/byron-genesis.json"       #Byron-Genesis path

cardanocli="cardano-cli"        #Path to your cardano-cli you wanna use
cardanonode="cardano-node"      #Path to your cardano-node you wanna use

magicparam="--mainnet"  #choose "--mainnet" for mainnet or for example "--testnet-magic 1097911063" for a testnet
addrformat="--mainnet"  #choose "--mainnet" for mainnet address format or like "--testnet-magic 1097911063" for testnet address format

itn_jcli="./jcli" #only needed if you wanna include your ITN witness for your pool-ticker

#--------- leave this next value until you have to change it for a testnet
byronToShelleyEpochs=208 #208 for the mainnet, 74 for the testnet
EOF
```


{% endtab %}

{% tab title="TestNet" %}
```
cp cardano/testnet/* ~/.local/bin/
cd ~/.local/bin/
```

Now we have to do a simple configuration so the script knows where to find files and the socket. We will place the configuration file in our home directory, so you don't have to edit files again when next time you decide to upgrade the script

```
cat <<EOF > ~/.common.inc
socket="/home/cardano/cnode/sockets/node.socket"

genesisfile="/home/cardano/cnode/config/testnet-shelley-genesis.json"           #Shelley-Genesis path
genesisfile_byron="/home/cardano/cnode/config/testnet-byron-genesis.json"       #Byron-Genesis path

cardanocli="cardano-cli"        #Path to your cardano-cli you wanna use
cardanonode="cardano-node"      #Path to your cardano-node you wanna use

magicparam="--testnet-magic 1097911063"  #choose "--mainnet" for mainnet or for example "--testnet-magic 1097911063" for a testnet
addrformat="--testnet-magic 1097911063"  #choose "--mainnet" for mainnet address format or like "--testnet-magic 1097911063" for testnet address format

itn_jcli="./jcli" #only needed if you wanna include your ITN witness for your pool-ticker

#--------- leave this next value until you have to change it for a testnet
byronToShelleyEpochs=74 #208 for the mainnet, 74 for the testnet
EOF
```
{% endtab %}
{% endtabs %}



Let's check if you have succeeded:

```
00_common.sh 
```

if you see the following output, then you have successfully installed the scripts:

<figure><img src="../.gitbook/assets/CleanShot 2024-09-28 at 16.38.06@2x.jpg" alt=""><figcaption></figcaption></figure>
