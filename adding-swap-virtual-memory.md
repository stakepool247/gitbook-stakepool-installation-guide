---
description: >-
  To prevent system process from crashing because of out-of-memory issues it is
  advised to add some extra space for swap memory.
---

# Adding SWAP (virtual ) memory

> **Memory swapping** is a computer technology that enables an operating system to provide more **memory** to a running application or process than is available in physical random access **memory** (**RAM**).\
> [https://www.enterprisestorageforum.com/hardware/what-is-memory-swapping/](https://www.enterprisestorageforum.com/hardware/what-is-memory-swapping/)

Swap is a space on a disk that is used when the amount of physical RAM memory, so let's add this to our Ubuntu server

## Before we start adding swap

let's check if your system has already enabled the swap by executing the following command:

```
swapon -s
```

{% hint style="warning" %}
if instead of an empty response you get something similar to this, then it means **you already have enabled swap space and you should skip this section** and move to the next one.
{% endhint %}

![Example of enabled swap](<.gitbook/assets/image (10).png>)

{% hint style="info" %}
The SWAP should not be seen as a replacement for physical memory (RAM). Since swap space is a section of the hard drive, it has a significantly slower speed than regular RAM. If your server constantly runs out of RAM, you should be adding more RAM to it
{% endhint %}

If you have 4-16GB of RAM then you should add 8 GB of SWAP space, for larger servers you can double that.

1. let's start by creating a SWAP file of 8GB

```
sudo fallocate -l 8G /swapfile
```

2\. Let's change the default permissions so that only the system can read/write to this file

```
sudo chmod 600 /swapfile
```

3\. Creating swap area and enabling the swap space

```
sudo mkswap /swapfile
sudo swapon /swapfile
```

4\. Let's add this to the system as a permanent solution (so it works also after rebooting the server)

```
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

5\. let's check if the swap is enabled and working

```
sudo swapon --show
```

now you can also check with the  `htop` command and you should see the used and total swap space

![](<.gitbook/assets/CleanShot 2021-04-07 at 23.08.17.png>)

6\. Let's also tune swap behavior so the system prefers real RAM and only uses swap under pressure:

```
# Add settings to sysctl.conf (persist across reboots)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf

# Apply immediately without reboot
sudo sysctl -p
```







