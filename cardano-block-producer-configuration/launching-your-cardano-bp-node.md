---
description: Configure and launch the block producer as a systemd service.
---

# Launching the block producer

With keys and certificates generated, transfer them to your BP server and start the node.

## 1) Transfer keys to the BP server

Copy these files to `/home/cardano/cnode/keys/` on your block producer:

| Source file | Destination |
|-------------|-------------|
| `myPool.kes-000.skey` | `myPool.kes.skey` |
| `myPool.vrf.skey` | `myPool.vrf.skey` |
| `myPool.node-000.opcert` | `myPool.node.opcert` |

Rename and secure the files:

```bash
cd ~/cnode/keys
mv myPool.kes-000.skey myPool.kes.skey
mv myPool.node-000.opcert myPool.node.opcert
chmod 400 *
```

## 2) Create the systemd service

{% tabs %}
{% tab title="Systemd service (recommended)" %}
Create the service file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/cardano-node.service
[Unit]
Description=Cardano Block Producer
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=cardano
Group=cardano
WorkingDirectory=/home/cardano/cnode
ExecStart=/home/cardano/.local/bin/cardano-node run \\
    --config /home/cardano/cnode/config/config.json \\
    --topology /home/cardano/cnode/config/topology.json \\
    --database-path /home/cardano/cnode/db \\
    --socket-path /home/cardano/cnode/sockets/node.socket \\
    --host-addr 0.0.0.0 \\
    --port 3001 \\
    --shelley-kes-key /home/cardano/cnode/keys/myPool.kes.skey \\
    --shelley-vrf-key /home/cardano/cnode/keys/myPool.vrf.skey \\
    --shelley-operational-certificate /home/cardano/cnode/keys/myPool.node.opcert
KillSignal=SIGINT
RestartKillSignal=SIGINT
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cardano-bp
LimitNOFILE=1048576
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cardano-node.service
sudo systemctl start cardano-node.service
```

If updating an existing service, reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart cardano-node.service
```

Check the logs:

```bash
journalctl -u cardano-node.service -f -o cat
```

![](<../.gitbook/assets/image (32).png>)
{% endtab %}

{% tab title="Script with tmux (testnet only)" %}
Create the launch script:

```bash
cd ~/cnode/scripts
nano node.sh
```

```bash
#!/bin/bash

cardano-node run \
 --database-path ~/cnode/db \
 --socket-path ~/cnode/sockets/node.socket \
 --host-addr 0.0.0.0 \
 --port 3001 \
 --config ~/cnode/config/config.json \
 --topology ~/cnode/config/topology.json \
 --shelley-kes-key ~/cnode/keys/myPool.kes.skey \
 --shelley-vrf-key ~/cnode/keys/myPool.vrf.skey \
 --shelley-operational-certificate ~/cnode/keys/myPool.node.opcert
```

Make it executable and run inside tmux:

```bash
chmod +x ~/cnode/scripts/node.sh
tmux new -s cardano
bash ~/cnode/scripts/node.sh
```

Detach from tmux: **Ctrl+B** then **D**. Reattach later with `tmux attach -t cardano`.
{% endtab %}
{% endtabs %}

---

## KES key rotation

{% hint style="warning" %}
KES (Key Evolving Signature) keys **expire** after a set number of periods (typically 62 periods, approximately 93 days). When they expire, your BP stops producing blocks.
{% endhint %}

Check your current KES status:

```bash
cardano-cli query kes-period-info --mainnet \
  --op-cert-file ~/cnode/keys/myPool.node.opcert
```

To rotate, generate new KES keys and operational certificate on your **offline machine**:

```bash
cd ~/cnode/keys
04c_genKESKeys.sh myPool cli
04d_genNodeOpCert.sh myPool
```

Transfer the new `myPool.kes.skey` and `myPool.node.opcert` to your BP server and restart the node.

Set a calendar reminder to rotate KES keys **every 80 days** to stay ahead of expiration.
