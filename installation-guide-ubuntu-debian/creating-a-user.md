---
description: Create a dedicated cardano user with sudo privileges.
---

# Creating the cardano user

## Add the user

Create a system user named `cardano`:

```bash
sudo adduser cardano
```

You will be prompted for a password and optional user details.

![](<../.gitbook/assets/terminal-adduser.png>)

## Grant sudo access

Add the user to the sudo group:

```bash
sudo usermod -aG sudo cardano
```

If the user was created without a password (e.g., via the setup script), enable passwordless sudo:

```bash
echo 'cardano ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/cardano
sudo chmod 440 /etc/sudoers.d/cardano
```

## Switch to the cardano user

```bash
sudo su - cardano
```

Verify you are logged in correctly:

```bash
whoami
```

Expected output: `cardano`
