---
description: Safe upgrade guide from older 8.x/9.x/10.x nodes to cardano-node 10.6.2
---

# Upgrade to 10.6.2 (safe operator flow)

This guide upgrades an existing relay/BP to **cardano-node 10.6.2** with minimal downtime.

## 0) Pre-checks

```bash
cardano-node --version
cardano-cli --version
systemctl status cardano-node --no-pager
```

Record current versions and ensure node is healthy before upgrade.

## 1) Download + verify release artifact

```bash
cd /tmp
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then FILE=cardano-node-10.6.2-linux-amd64.tar.gz; else FILE=cardano-node-10.6.2-linux-arm64.tar.gz; fi

curl -L -o "$FILE" "https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/$FILE"
curl -L -o cardano-node-10.6.2-sha256sums.txt "https://github.com/IntersectMBO/cardano-node/releases/download/10.6.2/cardano-node-10.6.2-sha256sums.txt"

sha256sum "$FILE"
cat cardano-node-10.6.2-sha256sums.txt
```

Ensure checksum matches exactly.

## 2) Backup binaries + configs

```bash
sudo cp -a /home/cardano/.local/bin/cardano-node /home/cardano/.local/bin/cardano-node.bak.$(date +%F-%H%M) || true
sudo cp -a /home/cardano/.local/bin/cardano-cli /home/cardano/.local/bin/cardano-cli.bak.$(date +%F-%H%M) || true
cp -a /home/cardano/cnode/config/mainnet /home/cardano/cnode/config/mainnet.bak.$(date +%F-%H%M)
```

## 3) Install new binaries

```bash
tar -xzf "$FILE"
install -m 755 ./bin/cardano-node ./bin/cardano-cli /home/cardano/.local/bin/
```

## 4) Refresh mainnet config bundle

```bash
mkdir -p /home/cardano/cnode/config/mainnet
cp -r ./share/mainnet/* /home/cardano/cnode/config/mainnet/
```

## 5) Restart node

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

```bash
sudo systemctl stop cardano-node
cp -a /home/cardano/.local/bin/cardano-node.bak.YYYY-MM-DD-HHMM /home/cardano/.local/bin/cardano-node
cp -a /home/cardano/.local/bin/cardano-cli.bak.YYYY-MM-DD-HHMM /home/cardano/.local/bin/cardano-cli
sudo systemctl start cardano-node
```

---

### Notes for 10.6.2

- Source builders must use **libblst 0.3.14**.
- `cardano-cli` version may differ from node version (this is expected in current packaging).
- Upgrade relay first, then BP (for safer pool operations).
