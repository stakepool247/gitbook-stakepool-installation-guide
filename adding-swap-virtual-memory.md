---
description: Add swap space to prevent out-of-memory crashes during node operation.
---

# Configuring swap space

Swap provides overflow memory on disk when physical RAM is exhausted. It prevents out-of-memory crashes but is significantly slower than real RAM.

## Check existing swap

```bash
swapon -s
```

{% hint style="warning" %}
If this shows an active swapfile, swap is already configured — skip to the next section.
{% endhint %}

![Example of enabled swap](<.gitbook/assets/terminal-swap-swapon.png>)

## Recommended swap size

| Server RAM | Swap size |
|-----------|-----------|
| 4 -- 16 GB | 8 GB |
| 16+ GB | 16 GB |

{% hint style="info" %}
Swap is not a replacement for physical RAM. If your server constantly uses swap, upgrade memory instead.
{% endhint %}

## Create and enable swap

1. Create an 8 GB swap file:

```bash
sudo fallocate -l 8G /swapfile
```

2. Restrict permissions:

```bash
sudo chmod 600 /swapfile
```

3. Initialize and enable the swap area:

```bash
sudo mkswap /swapfile
sudo swapon /swapfile
```

4. Make swap persistent across reboots:

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

5. Verify swap is active:

```bash
sudo swapon --show
free -h
```

![](<.gitbook/assets/terminal-swap-show.png>)

6. Tune swap behavior:

```bash
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
