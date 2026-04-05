---
description: Safe upgrade guide from older 8.x/9.x/10.x nodes to cardano-node 10.6.2.
---

# Upgrade to cardano-node 10.6.2

This guide upgrades an existing relay or block producer to **cardano-node 10.6.2** with minimal downtime.

{% hint style="info" %}
Upgrade your **relay nodes first**, then the block producer. This keeps the pool producing blocks while you validate the new version on relays.
{% endhint %}

## 0) Pre-checks

Record current versions and confirm the node is healthy before proceeding:

```bash
cardano-node --version
cardano-cli --version
systemctl status cardano-node --no-pager
```

## 1) Download and verify the release artifact

```bash
cd /tmp
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then FILE=cardano-node-10.6.2-linux-amd64.tar.gz; else FILE=cardano-node-10.6.2-linux-arm64.tar.gz; fi

curl -L -o "$FILE" "https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/$FILE"
curl -L -o cardano-node-10.6.2-sha256sums.txt "https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-sha256sums.txt"

sha256sum "$FILE"
cat cardano-node-10.6.2-sha256sums.txt
```

Verify the checksum matches exactly before continuing.

## 2) Back up binaries and configs

```bash
sudo cp -a /home/cardano/.local/bin/cardano-node /home/cardano/.local/bin/cardano-node.bak.$(date +%F-%H%M) || true
sudo cp -a /home/cardano/.local/bin/cardano-cli /home/cardano/.local/bin/cardano-cli.bak.$(date +%F-%H%M) || true
cp -a /home/cardano/cnode/config /home/cardano/cnode/config.bak.$(date +%F-%H%M)
```

## 3) Install new binaries

```bash
tar -xzf "$FILE"
install -m 755 ./bin/cardano-node ./bin/cardano-cli /home/cardano/.local/bin/
```

## 4) Refresh config files

For mainnet:

```bash
cp ./share/mainnet/* /home/cardano/cnode/config/
```

For pre-prod testnet, use `./share/preprod/*` instead.

## 5) Restart the node

```bash
sudo systemctl daemon-reload
sudo systemctl restart cardano-node
sleep 3
sudo systemctl status cardano-node --no-pager
```

## 6) Post-upgrade validation

```bash
cardano-node --version
cardano-cli --version
journalctl -u cardano-node -n 100 --no-pager
cardano-cli query tip --mainnet --socket-path /home/cardano/cnode/sockets/node.socket
```

## 7) Rollback (if needed)

List your backup files and restore the previous version:

```bash
ls /home/cardano/.local/bin/cardano-node.bak.*
```

```bash
sudo systemctl stop cardano-node
cp -a /home/cardano/.local/bin/cardano-node.bak.YYYY-MM-DD-HHMM /home/cardano/.local/bin/cardano-node
cp -a /home/cardano/.local/bin/cardano-cli.bak.YYYY-MM-DD-HHMM /home/cardano/.local/bin/cardano-cli
sudo systemctl start cardano-node
```

Replace `YYYY-MM-DD-HHMM` with the actual backup timestamp from the listing above.

---

## Notes

| Topic | Detail |
|-------|--------|
| Source builds | Must use **libblst 0.3.14** |
| CLI version | `cardano-cli` version may differ from node version (expected in current packaging) |
| Upgrade order | Relay first, then BP |
