---
description: Install cardano-node/cardano-cli 10.6.2 using official release binaries.
---

# Cardano Node installation process (10.6.2)

This section installs **cardano-node 10.6.2** from official GitHub release artifacts.

{% hint style="info" %}
Path layout is kept compatible with existing SPO setups: `/home/cardano/cnode/{config,db,sockets,keys,logs,scripts}`.
{% endhint %}

## 1) Download release artifacts

For **x86_64 / amd64** Linux:

```bash
cd /tmp
curl -L -o cardano-node-10.6.2-linux-amd64.tar.gz \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-linux-amd64.tar.gz
curl -L -o cardano-node-10.6.2-sha256sums.txt \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-sha256sums.txt
```

For **arm64** Linux, use:

```bash
cd /tmp
curl -L -o cardano-node-10.6.2-linux-arm64.tar.gz \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-linux-arm64.tar.gz
curl -L -o cardano-node-10.6.2-sha256sums.txt \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-sha256sums.txt
```

## 2) Verify checksum

```bash
sha256sum cardano-node-10.6.2-linux-amd64.tar.gz
cat cardano-node-10.6.2-sha256sums.txt
```

Compare the tarball checksum with the official checksum file.

## 3) Install binaries

```bash
tar -xzf cardano-node-10.6.2-linux-amd64.tar.gz
install -m 755 ./bin/cardano-node ./bin/cardano-cli $HOME/.local/bin/
```

If the archive contains `cardano-submit-api` and `cardano-tracer`, you can install them too:

```bash
[ -f ./bin/cardano-submit-api ] && install -m 755 ./bin/cardano-submit-api $HOME/.local/bin/
[ -f ./bin/cardano-tracer ] && install -m 755 ./bin/cardano-tracer $HOME/.local/bin/
```

## 4) Validate installation

```bash
which cardano-node
which cardano-cli
cardano-node --version
cardano-cli --version
```

You should see **cardano-node 10.6.2**. (`cardano-cli` version is released separately and may show a different semantic version, e.g. 10.15.x).

## 5) Install network configuration files

The release archive already contains current environment configs under `./share/`.

{% tabs %}
{% tab title="Mainnet" %}
```bash
cp ./share/mainnet/* $HOME/cnode/config/
```
{% endtab %}

{% tab title="Testnet (pre-prod)" %}
```bash
cp ./share/preprod/* $HOME/cnode/config/
```
{% endtab %}
{% endtabs %}

You can also fetch the latest configs from the Intersect environments page:

- https://book.play.dev.cardano.org/environments.html

---

✅ Done — cardano-node 10.6.2 binaries and configs are installed. Continue to the **Relay Configuration** section to set up and launch your node.
