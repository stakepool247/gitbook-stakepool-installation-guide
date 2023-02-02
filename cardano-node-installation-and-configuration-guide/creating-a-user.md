---
description: >-
  Before we start the installation process, let's create a user for our Cardano
  pool project. Let's name this user "cardano" and give the administrative user
  "power" to it.
---

# Creating a user for Cardano Node

## Creating a user

Let's start by creating our new user **"cardano"** by typing the following command:

```
sudo adduser cardano
```

by executing this command  you will be requested to enter your password and then to set a password for this user as well as additional information

![](<../.gitbook/assets/CleanShot 2020-08-08 at 13.05.29@2x.png>)

Congratulations - we just created our new user! Now - let's give this user administrative power by typing this:&#x20;

```
sudo usermod -aG sudo cardano
```

Great! Now the user cardano has administrative power! Whenever we need to run a command with administrative privilege-  run the command by adding in front of it additional command - **sudo**

{% hint style="info" %}
_**Sudo**_**,** the one command to rule them all. It stands for “super user do!” Pronounced like “sue dough”. **allows a permitted user to execute a command as root user (administrator/superuser)** allows a permitted user to execute a command as root user (administrator/super user)
{% endhint %}

Let's switch to our new user:

```
sudo su - cardano
```

> \
> cardano@localhost:\~$&#x20;

If everything goes as planned then you should be now logged in as user "cardano", let's double-check by typing:

```
whoami
```

as a reply,  you should see the current user username

> cardano@localhost:\~$ **whoami** \
> cardano

Let's check if we can execute commands with root privileges (as administrator) by typing:

```
sudo whoami
```

> cardano@localhost:\~$ sudo **whoami** \
> \[sudo] password for cardano: **xxx**\
> root

before you can execute commands as a root user, you will have to type the user's password (for Cardano user) to authenticate yourself. After authentication - you will see that the command this time was executed as a root user!&#x20;

Great!  We have created a user and let's proceed now to the installation process!
