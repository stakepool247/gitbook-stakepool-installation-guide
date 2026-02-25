---
description: Quick update guide from 8.x.x to 8.7.2
cover: >-
  https://images.unsplash.com/photo-1558494949-ef010cbdcc31?crop=entropy&cs=srgb&fm=jpg&ixid=MnwxOTcwMjR8MHwxfHNlYXJjaHwxfHxzZXJ2ZXJ8ZW58MHx8fHwxNjQ2MTM5ODI1&ixlib=rb-1.2.1&q=85
coverY: 0
---

# Upgrade to 8.7.2 from 8.0.0

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
ghcup install cabal 3.8.1.0
ghcup set ghc 8.10.7
ghcup set cabal 3.8.1.0
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

###

### Installing BLST

```
mkdir -p ~/git && cd ~/git
git clone https://github.com/supranational/blst
cd blst
git checkout v0.3.10
./build.sh
cat > libblst.pc << EOF
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libblst
Description: Multilingual BLS12-381 signature library
URL: https://github.com/supranational/blst
Version: 0.3.10
Cflags: -I\${includedir}
Libs: -L\${libdir} -lblst
EOF

sudo cp libblst.pc /usr/local/lib/pkgconfig/
sudo cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/
sudo cp libblst.a /usr/local/lib
sudo chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}

```

### Update/ install new libsodium version

```
mkdir -p ~/git && cd ~/git
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout dbb48cc
./autogen.sh
./configure
make
sudo make install

```

### 4. Downloading configuration files (leaving old topology file in place):

{% tabs %}
{% tab title="Mainnet" %}
<pre><code>cd ~/cnode/config

#downloading configuration files
curl -o config.json https://book.world.dev.cardano.org/environments/mainnet/config.json
curl -o byron-genesis.json https://book.world.dev.cardano.org/environments/mainnet/byron-genesis.json
curl -o shelley-genesis.json https://book.world.dev.cardano.org/environments/mainnet/shelley-genesis.json
curl -o alonzo-genesis.json https://book.world.dev.cardano.org/environments/mainnet/alonzo-genesis.json
curl -o conway-genesis.json https://book.world.dev.cardano.org/environments/mainnet/conway-genesis.json

# just in case you still have old naming 
<strong>mv mainnet-topology.json topology.json
</strong>#list downloaded files
ls -al *

</code></pre>
{% endtab %}

{% tab title="Testnet (PreProd)" %}
```
cd ~/cnode/config
#downloading configs
wget -q -O config.json https://book.world.dev.cardano.org/environments/preprod/config.json
wget -q -O alonzo-genesis.json https://book.world.dev.cardano.org/environments/preprod/alonzo-genesis.json
wget -q -O byron-genesis.json https://book.world.dev.cardano.org/environments/preprod/byron-genesis.json
wget -q -O shelley-genesis.json https://book.world.dev.cardano.org/environments/preprod/shelley-genesis.json
wget -q -O topology.json https://book.world.dev.cardano.org/environments/preprod/topology.json
wget -q -O conway-genesis.json https://book.world.dev.cardano.org/environments/preprod/conway-genesis.json
# just in case you still have old naming 
mv testnet-topology.json topology.json

#list downloaded files
ls -al 

```
{% endtab %}
{% endtabs %}



### 5. Proceeding with Cardano Node binary updates

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

# checking out the 8.7.2 version
git checkout tags/8.7.2
```

```
echo "package trace-dispatcher" >> cabal.project.local
echo "  ghc-options: -Wwarn" >> cabal.project.local
echo "" >> cabal.project.local
echo "package HsOpenSSL" >> cabal.project.local
echo "  flags: -homebrew-openssl" >> cabal.project.local
echo "" >> cabal.project.local
```

<pre><code># let's update cabal
<strong>cabal clean
</strong><strong>cabal update
</strong># now let's compile the code
cabal build cardano-node cardano-cli
</code></pre>

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

<figure><img src="../.gitbook/assets/CleanShot 2023-12-28 at 23.43.49@2x.jpg" alt=""><figcaption></figcaption></figure>



Now we can start the Cardano node process

```
sudo systemctl daemon-reload
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
👉🏼 Join our Telegram support Group: [https://t.me/StakePool247help](https://www.youtube.com/redirect?event=video_description\&redir_token=QUFFLUhqbFFLWlhNYkhpRlhYd3gyWkIwbU91R2ZhUmZzUXxBQ3Jtc0tuUko0cnVvanYwVktab1FWalVMb0ZOVEpmTDBNRXNSRWwwbWk0UE5tdkZYRENDZWRBYjlxMVYxMTdqdjBfeDB3WmhiTDRjNm13RDVSeDhDQ0JEOWZfVUlEX1RaRm10UlJsWXZkTzdIY29aeTEtMnN3aw\&q=https%3A%2F%2Ft.me%2FStakePool247help)
{% endhint %}

