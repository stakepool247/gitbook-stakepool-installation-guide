---
description: Let's generate the wallet keys for our pledge
---

# Generating wallet keys

let's go to our key folder

```
cd ~/cnode/keys/
```

Let's start by generating a wallet for paying fees and Pool deposit, let's call it myWallet

```
02_genPaymentAddrOnly.sh myWallet cli
ls -al
```

you should see something like this:

![](<../.gitbook/assets/image (5).png>)

Now let's check the balance of the wallet as well the address of that wallet:

```bash
01_queryAddress.sh myWallet
```

![](<../.gitbook/assets/image (1).png>)

ok, as expected, no funds on that wallet :) \
check the address of that wallet, in this case it's **(DONT'T SEND FUNDS TO THIS ADDRESS)**: addr\_test1vrl0cagj24t20dcsmljh5n2egg5pehpfmy6wtsul6resl0gpzsp7d&#x20;

{% hint style="info" %}
You will need around **505 ADA to complete the process**. 500 ADA for the Pool Key deoposit (You will get it back when you de-register your pool) and some more ADA for transactions as well as delegation key deposit.\
Send the 505 ADA to your freshly created address and then check again the wallet using the above command.\
\
**Continue when you have done that!**
{% endhint %}

When you have sent some ADA to your myWallet address, let's check again:

![](<../.gitbook/assets/image (4).png>)

Now let's create  an address where you will be storing the **pools Pledge**

```bash
03a_genStakingPaymentAddr.sh poolOwner cli
ls -al poolOwner*
```

![](<../.gitbook/assets/image (21).png>)

Great, now let's register the owner stake key on the blockchain, **myWallet** will pay for the transaction as well as for the deposit

```bash
03b_regStakingAddrCert.sh poolOwner myWallet
```

![](<../.gitbook/assets/image (28).png>)

Now let's check if our stake certificate is registered on blockchain:

```bash
03c_checkStakingAddrOnChain.sh poolOwner
```

![](<../.gitbook/assets/image (30).png>)

Ok, our primary Wallet and Pledge wallet is ready! Let's create in our next steps the POOL Keys.
