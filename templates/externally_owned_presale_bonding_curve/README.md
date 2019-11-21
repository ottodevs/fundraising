# Aragon externally owned presale and bonding curve template

## Description
Aragon externally owned presale and bonding curve template is intended to deploy the bonding curve between ANT and ANJ for Aragon Network Court, along with the presale.

This pseudo-DAO has no core apps Voting, Finance or Vault, only a Token Manager for the bonded token, and it's supposed to be controlled externally (by the Aragon Network DAO in the case of ANJ), so all governing permissions are set to an external single entity (which in case of ANJ will be the Agent of the Aragon Network DAO).

Because the purpose isn't either a real fundraising campaign, but only exchange functionality given by the bonding curve, it doesn't have a Tap mechanism either.

The presale used is the simple version, that when close redirects part of the balance of the collateral token to a beneficiary in order to adjust its price to the one that the bonding curve will have given the toal supply of bonded tokens minted and the defined reserve ratio.

## Usage

### Install fundraising apps

```
template.installFundraisingApps(
    owner,
    id,
    collateralToken,
    bondedToken,
    period,
    exchangeRate,
    openDate,
    reserveRatio,
    batchBlocks,
    slippage
)
```

- **owner** Owner that will control the pseudo-DAO
- **id** Id for org, will assign [id].aragonid.eth
- **collateralToken** Collateral token in bonding curve and presale
- **bondedToken** Bonded token in bonding curve and presale
- **period** The presale period
- **exchangeRate** The presale exchange rate [in PPM]
- **openDate** The date upon which the presale will be open [if 0, the presale can be open manually later]
- **reserveRatio** Reserve ratio of the bonding curve
- **batchBlocks** The number of blocks trading batches will last
- **slippage** To set up the maximum per-batch price slippage in the market maker

## Permissions

### System
_Handle apps and permissions_

| App               | Permission            | Grantee          | Manager          |
| ----------------- | --------------------- | ---------------- | ---------------- |
| Kernel            | APP_MANAGER           | Owner            | Owner            |
| ACL               | CREATE_PERMISSIONS    | Owner            | Owner            |


### Fundraising apps

#### Agent / Reserve
_Handle market maker funds_

| App  | Permission             | Grantee          | Manager          |
| ---- | ---------------------- | ---------------- | ---------------- |
| Pool | SAFE_EXECUTE           | Owner            | Owner            |
| Pool | ADD_PROTECTED_TOKEN    | Controller       | Owner            |
| Pool | REMOVE_PROTECTED_TOKEN | NULL             | NULL             |
| Pool | EXECUTE                | NULL             | NULL             |
| Pool | DESIGNATE_SIGNER       | NULL             | NULL             |
| Pool | ADD_PRESIGNED_HASH     | NULL             | NULL             |
| Pool | RUN_SCRIPT             | NULL             | NULL             |
| Pool | TRANSFER               | MarketMaker      | Owner            |


#### Presale
_Handle preliminary sale_

| App     | Permission | Grantee    | Manager          |
| ------- | ---------- | ---------- | ---------------- |
| Presale | OPEN       | Controller | Owner            |
| Presale | CONTRIBUTE | Controller | Owner            |


#### MarketMaker
_Handle buy and sell orders_

| App         | Permission              | Grantee    | Manager          |
| ----------- | ----------------------- | ---------- | ---------------- |
| MarketMaker | OPEN                    | Controller | Owner            |
| MarketMaker | UPDATE_FORMULA          | NULL       | NULL             |
| MarketMaker | UPDATE_BENEFICIARY      | Controller | Owner            |
| MarketMaker | UPDATE_FEES             | Controller | Owner            |
| MarketMaker | ADD_COLLATERAL_TOKEN    | Controller | Owner            |
| MarketMaker | REMOVE_COLLATERAL_TOKEN | Controller | Owner            |
| MarketMaker | UPDATE_COLLATERAL_TOKEN | Controller | Owner            |
| MarketMaker | OPEN_BUY_ORDER          | Controller | Owner            |
| MarketMaker | OPEN_SELL_ORDER         | Controller | Owner            |

#### Controller
_API contract forwarding transactions to relevant contracts_

| App        | Permission                            | Grantee | Manager |
| ---------- | ------------------------------------- | ------- | ------- |
| Controller | UPDATE_BENEFICIARY                    | NULL    | NULL    |
| Controller | UPDATE_FEES                           | NULL    | NULL    |
| Controller | ADD_COLLATERAL_TOKEN                  | Owner   | Owner   |
| Controller | REMOVE_COLLATERAL_TOKEN               | Owner   | Owner   |
| Controller | UPDATE_COLLATERAL_TOKEN               | Owner   | Owner   |
| Controller | UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT  | NULL    | NULL    |
| Controller | UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT | NULL    | NULL    |
| Controller | ADD_TOKEN_TAP                         | NULL    | NULL    |
| Controller | UPDATE_TOKEN_TAP                      | NULL    | NULL    |
| Controller | OPEN_PRESALE                          | Owner   | Owner   |
| Controller | OPEN_TRADING                          | Presale | Owner   |
| Controller | CONTRIBUTE                            | Any     | Owner   |
| Controller | OPEN_BUY_ORDER                        | Any     | Owner   |
| Controller | OPEN_SELL_ORDER                       | Any     | Owner   |
| Controller | WITHDRAW                              | NULL    | NULL    |
