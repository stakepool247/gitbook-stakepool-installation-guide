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

![creating and enabling cardano node as system service](<../.gitbook/assets/terminal-systemd-enable.png>)

Now let's check if our cardano node process is running!

```
journalctl -u cardano-node.service -f -o cat
```

<figure><img src="../.gitbook/assets/terminal-journalctl-sync.png" alt="journalctl showing cardano-node syncing"><figcaption></figcaption></figure>

**We have set up your first relay node!** &#x20;

**As a next step, repeat the installation and relay setup on your second relay server.** You need a minimum of 2 servers:

**1) Relay nodes** — publicly reachable servers that sit between your block producer and the rest of the Cardano network, shielding your BP from direct exposure.\
**2) Block producer (BP)** — the server that mints blocks, connected only to your relays.\
**3) Offline machine / hardware wallet** — a secure computer (never connected to the internet) where you generate stake pool keys and sign transactions.

Ideally, run 2 relay nodes for each block producer:

![](<../.gitbook/assets/topology-diagram.png>)

### Topology: connecting your relays to your BP

After you set up your block producer, you need to edit `topology.json` on **each** server so they know about each other.

#### On each relay — add your BP as a local root peer

Edit `~/cnode/config/topology.json` on each relay. Add your BP's **private IP** in the first `localRoots` group (your own infrastructure, `trustable: true`). You can optionally add a second group with friendly pool relays:

```json
{
  "bootstrapPeers": [
    { "address": "backbone.cardano.iog.io", "port": 3001 },
    { "address": "backbone.mainnet.emurgornd.com", "port": 3001 },
    { "address": "backbone.mainnet.cardanofoundation.org", "port": 3001 }
  ],
  "localRoots": [
    {
      "accessPoints": [
        { "address": "YOUR_BP_PRIVATE_IP", "port": 3001, "description": "my BP" },
        { "address": "YOUR_OTHER_RELAY_IP", "port": 3001, "description": "my relay 2" }
      ],
      "advertise": false,
      "trustable": true,
      "hotValency": 2
    }
  ],
  "publicRoots": [
    { "accessPoints": [], "advertise": false }
  ],
  "useLedgerAfterSlot": 128908821
}
```

#### On the BP — add your relays only

Edit `~/cnode/config/topology.json` on your BP. Add **all your relay IPs** and set `useLedgerAfterSlot` to `-1` so the BP **only** connects to your relays and never to random peers. Remove `bootstrapPeers` entries:

```json
{
  "bootstrapPeers": [],
  "localRoots": [
    {
      "accessPoints": [
        { "address": "YOUR_RELAY1_IP", "port": 3001, "description": "relay 1" },
        { "address": "YOUR_RELAY2_IP", "port": 3001, "description": "relay 2" }
      ],
      "advertise": false,
      "trustable": true,
      "hotValency": 2
    }
  ],
  "publicRoots": [
    { "accessPoints": [], "advertise": false }
  ],
  "useLedgerAfterSlot": -1
}
```

{% hint style="info" %}
**`hotValency`** — the number of peers the node will actively maintain connections to. Set it to the number of your own nodes in that group.

**`trustable: true`** — use this for your own infrastructure (BP and relays). For external/friendly pool peers, use `trustable: false`.

**`useLedgerAfterSlot: -1`** on the BP prevents it from discovering and connecting to random peers. Your BP should only talk to your own relays.
{% endhint %}

After editing topology on any server, restart the node:

```
sudo systemctl restart cardano-node
```

{% hint style="danger" %}
**NEVER generate your wallet and stake pool keys on your online servers!** Use an offline (air-gapped) machine running Ubuntu, or a hardware wallet (Trezor/Ledger). Anyone with access to your keys has full control over your pool and funds.
{% endhint %}

**If you need any help:** [**https://t.me/StakePool247help**](https://t.me/StakePool247help)
