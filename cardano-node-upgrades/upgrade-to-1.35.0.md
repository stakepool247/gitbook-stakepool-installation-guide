---
description: Quick update guide from 1.34.x (or older) to 1.35.5
cover: >-
  https://images.unsplash.com/photo-1558494949-ef010cbdcc31?crop=entropy&cs=srgb&fm=jpg&ixid=MnwxOTcwMjR8MHwxfHNlYXJjaHwxfHxzZXJ2ZXJ8ZW58MHx8fHwxNjQ2MTM5ODI1&ixlib=rb-1.2.1&q=85
coverY: 0
---

# Upgrade to 1.35.5 from 1.3x.x

### 1. backing up current binaries

```
cd ~/.local/bin/

# let's create a folder with the version number
mkdir -p $(cardano-node version | grep -oP '(?<=cardano-node )[0-9\.]+')

# copying files to the created folder
cp cardano-node $(cardano-node version | grep -oP '(?<=cardano-node )[0-9\.]+')/
cp cardano-cli $(cardano-node version | grep -oP '(?<=cardano-node )[0-9\.]+')/
```

### 2. Upgrading and updating the system packages

```
# let's update the system first
sudo bash -c 'sudo apt-get update -y; sudo apt-get upgrade -y'
```

### 3. Updating the Cardano node requirements

```
ghcup install ghc 8.10.7
ghcup install cabal 3.6.2.0
ghcup set ghc 8.10.7
ghcup set cabal 3.6.2.0
```

```
sudo apt install -y libsodium-dev libtool autoconf make
```

```
mkdir -p ~/git && cd ~/git
rm -rf secp256k1
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
git checkout ac83be33
./autogen.sh
./configure --enable-module-schnorrsig --enable-experimental
make
sudo make install
```

### 4. Proceeding with Cardano Node binary updates

```
# let's create a directory where we will be downloading source code
cd ~ && mkdir -p git
cd git
```

```
# just in case you already had a source directory with cardano-node source code - let's delete it and download fresh one.
rm -rf cardano-node
```

```
# let's clone source code from git
git clone https://github.com/input-output-hk/cardano-node.git

cd cardano-node
git fetch --all --recurse-submodules --tags

# checking out the 1.35.5 version
git checkout tags/1.35.5

```

```
# adding extra flags for libsodium library
echo "package cardano-crypto-praos" >>  cabal.project.local
echo "  flags: -external-libsodium-vrf" >>  cabal.project.local
echo "with-compiler: ghc-8.10.7" >> cabal.project.local
```

```
# let's update cabal
cabal update
# now let's compile the code
cabal build all
```

And now we wait...  it could take some while (1h+ ) to compile, depending on your server's CPU&#x20;

![](https://media3.giphy.com/media/2uwZ4xi75JhxZYeyQB/giphy.gif?cid=ecf05e47cuuc11ypr2nr7rd48wieckoimcj9018ykxtsr6nc\&rid=giphy.gif\&ct=g)

{% hint style="warning" %}
Before the next step -  STOP your node so it doesn't lock the carano-node file for overwriting
{% endhint %}

```
sudo systemctl stop cardano-node
```

```
mkdir -p ~/.local/bin
cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/

```

```
# let's check if we have successfully installed the latst cardano-node and cardano-cli versions.
which cardano-node && which cardano-cli
cardano-node --version
cardano-cli --version
```

you should now have similar output:

![](<../.gitbook/assets/CleanShot 2022-08-28 at 11.41.51@2x.jpg>)

### 5. Updating the systemd service file

we need to add the Environment variable **LD\_LIBRARY\_PATH** for the node to work correctly.

{% tabs %}
{% tab title="Mainnet" %}
```
sudo rm /etc/systemd/system/cardano-node.service
cat <<EOF | sudo tee -a /etc/systemd/system/cardano-node.service
[Unit]
Description=Cardano Pool
After=multi-user.target
[Service]
Type=simple
ExecStart=/home/cardano/.local/bin/cardano-node run --config /home/cardano/cnode/config/mainnet-config.json --topology /home/cardano/cnode/config/mainnet-topology.json --database-path  /home/cardano/cnode/db/ --socket-path  /home/cardano/cnode/sockets/node.socket --host-addr 0.0.0.0 --port 3001    
Environment="LD_LIBRARY_PATH=/usr/local/lib"
KillSignal = SIGINT
RestartKillSignal = SIGINT
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cardano
LimitNOFILE=32768


Restart=on-failure
RestartSec=45s
WorkingDirectory=~
User=cardano
Group=cardano
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
```
{% endtab %}

{% tab title="TestNet" %}
```
sudo rm /etc/systemd/system/cardano-node.service
cat <<EOF | sudo tee -a /etc/systemd/system/cardano-node.service
[Unit]
Description=Cardano Pool
After=multi-user.target
[Service]
Type=simple
ExecStart=/home/cardano/.local/bin/cardano-node run --config /home/cardano/cnode/config/testnet-config.json --topology /home/cardano/cnode/config/testnet-topology.json --database-path  /home/cardano/cnode/db/ --socket-path  /home/cardano/cnode/sockets/node.socket --host-addr 0.0.0.0 --port 3001    
Environment="LD_LIBRARY_PATH=/usr/local/lib"
KillSignal = SIGINT
RestartKillSignal = SIGINT
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cardano
LimitNOFILE=32768


Restart=on-failure
RestartSec=45s
WorkingDirectory=~
User=cardano
Group=cardano
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
```
{% endtab %}
{% endtabs %}

Now we can start the cardano node process

```
sudo systemctl start cardano-node
```

and check the log files if everything is starting up as planned:

```
journalctl -u cardano-node.service -f -o cat
```

![](<../.gitbook/assets/CleanShot 2021-09-29 at 17.24.47@2x.png>)

**that's it - you have upgraded your node to the latest cardano-node version, now do the same update on all of your other production servers (or copy generated cardano-cli / cardano-node bin files).**

{% hint style="info" %}
Need help?\
👉🏼 Join our Telegram support Group: [https://t.me/StakePool247help](https://www.youtube.com/redirect?event=video\_description\&redir\_token=QUFFLUhqbFFLWlhNYkhpRlhYd3gyWkIwbU91R2ZhUmZzUXxBQ3Jtc0tuUko0cnVvanYwVktab1FWalVMb0ZOVEpmTDBNRXNSRWwwbWk0UE5tdkZYRENDZWRBYjlxMVYxMTdqdjBfeDB3WmhiTDRjNm13RDVSeDhDQ0JEOWZfVUlEX1RaRm10UlJsWXZkTzdIY29aeTEtMnN3aw\&q=https%3A%2F%2Ft.me%2FStakePool247help)
{% endhint %}

****
