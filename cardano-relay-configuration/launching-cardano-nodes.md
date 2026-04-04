---
description: Set up cardano-node as a systemd service so it runs in the background and survives reboots.
---

# Launching Cardano Relay Node

Running cardano-node as a **systemd service** is the recommended approach for production servers. The node will start automatically on boot and restart on failure.

Create a **systemd** service configuration file so the **cardano node process will run in the background:**

```
cat <<EOF | sudo tee /etc/systemd/system/cardano-node.service
[Unit]
Description=Cardano Relay Node
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
    --port 3001
KillSignal=SIGINT
RestartKillSignal=SIGINT
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cardano-relay
LimitNOFILE=1048576
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

let's reload systemd, enable the service (auto-start on boot) and start it:

```
sudo systemctl daemon-reload
sudo systemctl enable cardano-node.service
sudo systemctl start cardano-node.service
```

![creating and enabling cardano node as system service](<../.gitbook/assets/CleanShot 2021-08-30 at 15.23.30.png>)

Now let's check if our cardano node process is running!

```
journalctl -u cardano-node.service -f -o cat
```

<figure><img src="../.gitbook/assets/CleanShot 2023-05-15 at 20.16.13@2x.jpg" alt=""><figcaption></figcaption></figure>

**We have set up your first relay node!** &#x20;

**As a next step, repeat the installation and relay setup on your second relay server.** You need a minimum of 2 servers:

**1) Relay nodes** — publicly reachable servers that sit between your block producer and the rest of the Cardano network, shielding your BP from direct exposure.\
**2) Block producer (BP)** — the server that mints blocks, connected only to your relays.\
**3) Offline machine / hardware wallet** — a secure computer (never connected to the internet) where you generate stake pool keys and sign transactions.

Ideally, run 2 relay nodes for each block producer:

![](<../.gitbook/assets/image (11).png>)

### Topology: connecting your relays to your BP

After you set up your block producer, you'll need to add it as a **local root peer** in each relay's `topology.json`. Edit `~/cnode/config/topology.json` on each relay and add your BP's private IP under `localRoots`:

```json
"localRoots": [
  { "accessPoints": [
      { "address": "YOUR_BP_PRIVATE_IP", "port": 3001 }
    ],
    "advertise": false,
    "trustable": true,
    "valency": 1
  }
]
```

Similarly, on your BP's `topology.json`, add your relay IPs as local roots and set `useLedgerAfterSlot` to `-1` (BP should never connect to random peers):

```json
"useLedgerAfterSlot": -1
```

After editing topology, restart the node: `sudo systemctl restart cardano-node`

{% hint style="danger" %}
**NEVER generate your wallet and stake pool keys on your online servers!** Use an offline (air-gapped) machine running Ubuntu, or a hardware wallet (Trezor/Ledger). Anyone with access to your keys has full control over your pool and funds.
{% endhint %}

**If you need any help:** [**https://t.me/StakePool247help**](https://t.me/StakePool247help)
