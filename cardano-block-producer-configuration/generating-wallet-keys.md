---
description: Generate payment and staking keys for pool pledge and transaction fees.
---

# Generating wallet keys

All key generation should happen in your `~/cnode/keys/` directory.

```bash
cd ~/cnode/keys/
```

## 1) Create a payment wallet

Generate a payment-only wallet (`myWallet`) for paying transaction fees and the pool deposit:

```bash
02_genPaymentAddrOnly.sh myWallet cli
ls -al
```

![](<../.gitbook/assets/image (5).png>)

## 2) Check the wallet balance

```bash
01_queryAddress.sh myWallet
```

![](<../.gitbook/assets/image (1).png>)

The wallet is empty — expected for a new address.

{% hint style="info" %}
You need approximately **505 ADA** to complete pool registration:

| Purpose | Amount |
|---------|--------|
| Pool key deposit | 500 ADA (refunded when you de-register the pool) |
| Delegation key deposit | ~2 ADA |
| Transaction fees | ~3 ADA |

Send 505 ADA to the address shown by the query command above, then verify the balance before continuing.
{% endhint %}

After funding, verify the balance:

```bash
01_queryAddress.sh myWallet
```

![](<../.gitbook/assets/image (4).png>)

## 3) Create a staking/pledge address

Generate the address that will hold your pool's pledge:

```bash
03a_genStakingPaymentAddr.sh poolOwner cli
ls -al poolOwner*
```

![](<../.gitbook/assets/image (21).png>)

## 4) Register the stake key on-chain

Register the owner stake key. `myWallet` pays for the transaction and deposit:

```bash
03b_regStakingAddrCert.sh poolOwner myWallet
```

![](<../.gitbook/assets/image (28).png>)

## 5) Verify registration

```bash
03c_checkStakingAddrOnChain.sh poolOwner
```

![](<../.gitbook/assets/image (30).png>)

The payment wallet and pledge wallet are ready. Continue to generating pool keys.
