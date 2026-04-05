---
description: Install cardano-node and cardano-cli 10.6.2 from official release binaries.
---

# Installing cardano-node 10.6.2

This section installs **cardano-node 10.6.2** from official GitHub release artifacts.

{% hint style="info" %}
Path layout: `/home/cardano/cnode/{config,db,sockets,keys,logs,scripts}` — kept compatible with existing SPO setups.
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

For **arm64** Linux:

```bash
cd /tmp
curl -L -o cardano-node-10.6.2-linux-arm64.tar.gz \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-linux-arm64.tar.gz
curl -L -o cardano-node-10.6.2-sha256sums.txt \
  https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-sha256sums.txt
```

## 2) Verify checksum

```bash
sha256sum cardano-node-10.6.2-linux-*.tar.gz
cat cardano-node-10.6.2-sha256sums.txt
```

Compare your tarball's checksum with the matching line in the official checksums file. They must match exactly.

## 3) Install binaries

Extract the tarball (use the correct filename for your architecture):

```bash
tar -xzf cardano-node-10.6.2-linux-*.tar.gz
install -m 755 ./bin/cardano-node ./bin/cardano-cli $HOME/.local/bin/
```

Optionally install additional tools if present in the archive:

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

You should see **cardano-node 10.6.2**. The `cardano-cli` version is released separately and may show a different version (e.g., 10.15.x).

## 5) Install network configuration files

The release archive contains environment configs under `./share/`:

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

Latest configs are also available from the [Intersect environments page](https://book.play.dev.cardano.org/environments.html).

---

Binaries and configs are installed. Continue to **Relay Configuration** to set up and launch your node.
