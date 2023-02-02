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
Description=Cardano Pool
After=multi-user.target
[Service]
Type=simple
ExecStart=/home/cardano/.local/bin/cardano-node run \
--config /home/cardano/cnode/config/mainnet-config.json \
--topology /home/cardano/cnode/config/mainnet-topology.json \
--database-path  /home/cardano/cnode/db/  \
--socket-path  /home/cardano/cnode/sockets/node.socket \
--host-addr 0.0.0.0 \
--port 3001 \
--shelley-kes-key /home/cardano/cnode/keys/myPool.kes.skey \
--shelley-vrf-key /home/cardano/cnode/keys/myPool.vrf.skey \
--shelley-operational-certificate /home/cardano/cnode/keys/myPool.node.opcert


KillSignal = SIGINT
RestartKillSignal = SIGINT
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cardano
LimitNOFILE=32768


Restart=on-failure
RestartSec=45s
WorkingDirectory=~
User=cardano
Group=cardano
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



![](<../.gitbook/assets/image (3).png>)

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
 --database-path ~/cnode/db/ \
 --socket-path ~/cnode/sockets/node.socket \
 --host-addr 0.0.0.0 \
 --port 3000 \
 --config ~/cnode/config/mainnet-config.json \
 --topology ~/cnode/config/mainnet-topology.json \
 --shelley-kes-key ~/cnode/keys/myPool.kes.skey \
 --shelley-vrf-key ~/cnode/keys/myPool.vrf.skey \
 --shelley-operational-certificate ~/cnode/keys/myPool.node.opcert
```

save by pressing **`ctrl+x`** and then **`Y`**

now**, just start your node with start\_all.sh** - you should have a fully functional BP node!
{% endtab %}
{% endtabs %}



