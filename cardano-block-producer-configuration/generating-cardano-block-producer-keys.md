---
description: Let's create our pool keys
---

# Generating Cardano Block producer keys

With SPOS scripts this task is a super easy task:

```
04a_genNodeKeys.sh myPool
04b_genVRFKeys.sh myPool
04c_genKESKeys.sh myPool
04d_genNodeOpCert.sh myPool

# let's see generated files
ls -al myPool*
```

![](<../.gitbook/assets/image (20).png>)

Now you have generated your pool keys!&#x20;

### StakePool certificate generation

```
05a_genStakepoolCert.sh myPool
```

This command will generate a template that you have to fill in so we can generate a valid pool certificate

![](<../.gitbook/assets/image (30).png>)

```
nano myPool.pool.json 
```

I'm creating a **single owner pool** with the following configuration:

* **Pools Pledge:** 1mil ADA (will be held in **poolOwner address**)
* **Fixed Fee**: 340 ADA (This is currently the minimum you can set)
* **Pools Margin:** 5%&#x20;
* **2 IP relays**: 89.191.111.111 and 89.191.111.112, both will run on port 3001
* **Pool's TICKER:** XPOOL
* **short and long descriptions:** "My Testnet Pool #2",  "This pool is used for the guide i created",
* **main metadata** file will be stored at the following url: [https://www.stakepool247.eu/xpool-testnet.metadata.json](https://www.stakepool247.eu/xpool-testnet.metadata.json)****
* **extended metadata** (used by adapools, pooltool, and other services): [https://www.stakepool247.eu/xpool-testnet.extended.json](https://www.stakepool247.eu/xpool-testnet.extended.json)

![](<../.gitbook/assets/image (15).png>)

Let's run again the same command

```
05a_genStakepoolCert.sh myPool
```

![](<../.gitbook/assets/image (13).png>)

as we previously didn't have an **extended metadata file,** the script created a template, which we will edit and re-run the command once again.&#x20;

```
05a_genStakepoolCert.sh myPool
```

edit it so it corresponds to your needs, this file is just for additional information.

![](<../.gitbook/assets/image (3).png>)

when you have edited it, let's run the same command again:

```
nano myPool.additional-metadata.json 
```

![](<../.gitbook/assets/image (12).png>)

you will get 2 reminders to upload the 2 generated metadata files (myPool.extended-metadata.jsonmyPool.metadata.json) to your webserver. **This is mandatory for your pool to be visible on Daedalus and other wallets:**

* Don't forget to upload your myPool.metadata.json file now to your webserver ([https://www.stakepool247.eu/xpool-testnet.metadata.json](https://www.stakepool247.eu/xpool-testnet.metadata.json)) before running 05b & 05c !
* Don't forget to upload your myPool.extended-metadata.json file now to your webserver ([https://www.stakepool247.eu/xpool-testnet.extended.json](https://www.stakepool247.eu/xpool-testnet.extended.json)) before running 05b & 05c !

so, let's rename them as we defined them in our config files a

```
cp myPool.metadata.json xpool-testnet.metadata.json
cp myPool.extended-metadata.json xpool-testnet.extended.json
```

and upload to a webserver (either by ftp/sftp or any other means), **when it's done, let's proceed.**

Let's create a delegation certificate where we will delegate to our own pool

```
05b_genDelegationCert.sh myPool poolOwner
```

this will generate the **poolOwner.deleg.cert**\
****\
**before proceeding let's honor our pledge and send the pledged amount to poolOwner.paymet address, you can find the address where you have to send your funds in the poolOwner.payment.addr  file**

```
cat poolOwner.payment.addr 
```

![](<../.gitbook/assets/image (9).png>)

send your pledge to that address and check in few seconds if it has arrived:

```
01_queryAddress.sh poolOwner.payment
```

![](<../.gitbook/assets/image (32).png>)

Great, fund arrived - let's move forward.



**As the final task - let's register the stake pool on the blockchain**  (fees paid by the **myWallet**)

```
05c_regStakepoolCert.sh myPool myWallet
```

![](<../.gitbook/assets/image (28).png>)

So, if you did everything correctly in few minutes (sometimes hours) you will have your freshlly registred pool on Daedalus:

![](<../.gitbook/assets/image (4).png>)
