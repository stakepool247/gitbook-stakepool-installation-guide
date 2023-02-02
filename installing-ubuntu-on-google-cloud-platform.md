---
description: Quick intro on installing Ubuntu Virtual Machine on Google Cloud Platform
---

# Installing Ubuntu on Google Cloud Platform

## Google Cloud Platform registration:

go to: [https://console.cloud.google.com/](https://console.cloud.google.com/) and register for Google Cloud Platform services

when the registration is done you should be in your dashboard, which looks similar to this:

![Google Cloud Platform Dashboard](<.gitbook/assets/CleanShot 2020-08-08 at 12.40.57@2x.png>)

Now navigate from the main menu to **VM Instances** dashboard: **(Main Menu --> Compute Engine --> VM Instances)**

![VM Instance Dashboard](<.gitbook/assets/CleanShot 2020-08-08 at 12.43.15@2x.png>)

**Click on "Create"**

![](<.gitbook/assets/CleanShot 2020-08-08 at 12.44.24@2x (1).png>)

Let's name our server (VM instance): **cardano-core**

Region: choose what's best (or which is cheaper: in US Iowa is usually the cheaper - in EU: Finland)

Let's edit the Machine configuration: choose N1 Server: 2vCPU server with 7,5GB RAM (this will cost us \~49USD per month)

![](<.gitbook/assets/CleanShot 2020-08-08 at 12.46.09@2x.png>)

**Now let's choose Linux flavor and boot disk size, click on the "Change" button:**

![](<.gitbook/assets/CleanShot 2020-08-08 at 12.52.35@2x.png>)

**Let's go for Ubuntu 20.04 LTS with 100GB disk space:**

![](<.gitbook/assets/CleanShot 2020-08-08 at 12.51.04@2x.png>)

**click select, and that's it, we are ready to go:**

****
