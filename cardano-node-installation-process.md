---
description: >-
  After we have done all the prerequisites we are finally ready to do the
  installation process of Cardano Node!
---

# Cardano Node Installation process

Let's start by downloading the Cardano Node source code from git (GitHub)

```
mkdir -p ~/git && cd ~/git
git clone https://github.com/input-output-hk/cardano-node.git
```

![git clone in action](<.gitbook/assets/CleanShot 2021-08-30 at 13.38.13.png>)

You should have now a new folder - _cardano-node_ with the source code of the cardano node, let's go to that directory and choose which version we would like to install (compile)

```
cd cardano-node
git fetch --all --recurse-submodules --tags

#git checkout $(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest| jq .tag_name -r)
git checkout 1.35.4
```

you should see the following output, check if the desired version is selected:

![](<.gitbook/assets/CleanShot 2022-06-27 at 14.48.22@2x.jpg>)

let's add the libsodium libraries to Cardano node project as well as force to use our installed GHC version:

```
echo "package cardano-crypto-praos" >> cabal.project.local
echo "  flags: -external-libsodium-vrf" >> cabal.project.local
echo "with-compiler: ghc-8.10.7" >> cabal.project.local

```

Now we are ready to start the installation (compilation) process. \
This will take a while... if you are installing this on the VPS server, then you can go and grab coffee/beer/wine/water... as it will take a while.&#x20;

We will run this process in the background, so if your connection is interrupted, then it will still continue.&#x20;

```
cabal build all &
```

as the last step in our installation process is to copy newly compiled bin (executive) files to an early created folder: _.local/bin_

{% hint style="warning" %}
_if you had a previous version of Cardano node running, then before you copy the new binary files, make sure that you have stopped your current Cardano-node processes, otherwise, you will not be able to overwrite the new file._&#x20;
{% endhint %}

```
mkdir -p ~/.local/bin
cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/
echo PATH="$PATH:$HOME/.local/bin/" >> $HOME/.bashrc
source ~/.bashrc
```

Let's check if we have installed the binary files in the correct location and the latest version

```
which cardano-node && which cardano-cli
cardano-node --version
cardano-cli --version

```

you should see something like this:

<figure><img src=".gitbook/assets/CleanShot 2022-11-14 at 23.06.35@2x.jpg" alt=""><figcaption></figcaption></figure>

Great! We have installed the Cardano node on our server! \


Congratulations on installing Cardano Node!
