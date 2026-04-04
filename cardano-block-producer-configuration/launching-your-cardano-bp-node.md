---
description: let's launch your block producing node!
---

# Launching your Cardano BP node!

when all the certificates and keys are generated, now we have to adjust the launch script on our block producing node&#x20;

copy following files to your BP server and place them under **/home/$USER/cnode/keys/**

* myPool.kes-000.skey
* myPool.vrf.skey
* myPool.node-000.opcert

rename keys to default names so you don't have to edit your script/service config&#x20;

```
cd ~/cnode/keys
mv myPool.kes-000.skey myPool.kes.skey
mv myPool.node-000.opcert myPool.node.opcert

# setting read only access to ourselves and restrictin any access for other users
chmod 400 *
```

there are 2 ways you can launch your node:

1. launching as a script using tmux (recommended only for testnet or for any other **non-production server** )
2. launching as a system service **(RECOMENDED on production servers**)&#x20;

{% tabs %}
{% tab title="Launching as Systemd Service" %}
create a **systemd** service configuration file with all the keys and other settings, so the **cardano node process will be running in the background:**

```
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



If you haven't previously installed systemd service, then let's do it now and start the cardano node service as a system service

```
sudo systemctl enable cardano-node.service
sudo systemctl start cardano-node.service
```

if you have **previously already installed  systemd service**, then you just need to reload the configuration and restart the node

```
sudo systemctl daemon-reload 
sudo systemctl restart cardano-node.service
```



![](<../.gitbook/assets/image (32).png>)

you can check the cardano nodes live logfile using journalctl

```
journalctl -u cardano-node.service -f -o cat
```

congratulations! you have installed a block-producing node!
{% endtab %}

{% tab title="Launching from script" %}


```
cd ~/cnode/scripts
nano node.sh
```

and add the keys to your launch script

```
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

save by pressing **`ctrl+x`** and then **`Y`**

make the script executable and run it inside tmux so it survives disconnects:

```
chmod +x ~/cnode/scripts/node.sh
tmux new -s cardano
bash ~/cnode/scripts/node.sh
```

To detach from tmux: press **`ctrl+b`** then **`d`**. Reattach later with `tmux attach -t cardano`.
{% endtab %}
{% endtabs %}

---

### Important: KES key rotation

{% hint style="warning" %}
Your KES (Key Evolving Signature) keys **expire** after a set number of periods (typically 62 periods = \~1.5 days per period = \~93 days). When they expire, your BP will stop producing blocks.

You must rotate your KES keys and generate a new operational certificate before they expire. Use the SPOS scripts:

```bash
cd ~/cnode/keys
04c_genKESKeys.sh myPool cli
04d_genNodeOpCert.sh myPool
```

Then copy the new `myPool.kes.skey` and `myPool.node.opcert` to your BP server and restart the node.

Check your current KES period with:

```bash
cardano-cli query kes-period-info --mainnet \
  --op-cert-file ~/cnode/keys/myPool.node.opcert
```

Set a calendar reminder to rotate KES keys every 80 days to stay safe.
{% endhint %}



