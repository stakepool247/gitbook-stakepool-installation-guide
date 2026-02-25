---
description: Install cardano-node/cardano-cli 10.6.2 using official release binaries.
---

# Cardano Node installation process (10.6.2)

This section installs **cardano-node 10.6.2** from official GitHub release artifacts.

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
https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-linux-arm64.tar.gz
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
[ -f cardano-submit-api ] && install -m 755 cardano-submit-api $HOME/.local/bin/
[ -f cardano-tracer ] && install -m 755 cardano-tracer $HOME/.local/bin/
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

Copy mainnet files:

```bash
mkdir -p $HOME/cardano/files/mainnet
cp -r ./share/mainnet/* $HOME/cardano/files/mainnet/
```

If you prefer, you can fetch from Intersect environments page:

- https://book.play.dev.cardano.org/environments.html

## 6) Prepare systemd service (example)

Create `/etc/systemd/system/cardano-node.service`:

```ini
[Unit]
Description=Cardano Node
After=network-online.target
Wants=network-online.target

[Service]
User=cardano
Type=simple
Restart=always
RestartSec=5
LimitNOFILE=1048576
WorkingDirectory=/home/cardano/cardano
ExecStart=/home/cardano/.local/bin/cardano-node run \
  --topology /home/cardano/cardano/files/mainnet/topology.json \
  --database-path /home/cardano/cardano/db \
  --socket-path /home/cardano/cardano/ipc/node.socket \
  --host-addr 0.0.0.0 \
  --port 6000 \
  --config /home/cardano/cardano/files/mainnet/config.json

[Install]
WantedBy=multi-user.target
```

Then enable/start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cardano-node
sudo systemctl start cardano-node
sudo systemctl status cardano-node --no-pager
```

## 7) Check sync progress

```bash
journalctl -u cardano-node -f
```

In another terminal:

```bash
cardano-cli query tip --mainnet --socket-path /home/cardano/cardano/ipc/node.socket
```

When `syncProgress` approaches `100`, the node is near tip.

---

✅ Done — node 10.6.2 is installed and running.
