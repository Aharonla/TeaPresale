# TEA Presale Smart Contracts

## Summary

### Presale Smart Contract Documentation

#### Overview

The Presale smart contract facilitates the sale of tokens in rounds with customizable parameters such as start time, duration, token size, and price. It also supports referral tracking and allows users to buy tokens using specified payment tokens.

#### Contract Structure

The Presale contract inherits from the ERC20 token contract, making it both a presale mechanism and a token contract. It also inherits from the Ownable and Pausable contracts for ownership and pausing functionality.

#### Core Components

- **Round Struct**: Contains parameters for each round of the presale, including start time, duration, token size, price, and the number of tokens sold.
  
- **Referral Struct**: Tracks referral-related information such as the amount of tokens sold by a referral and the number of referrals made.

- **Constants**: Defines a constant `PERCENTAGE_RATE` representing the percentage rate with two decimal places.

- **State Variables**:
  - `currentRound`: Tracks the current presale round.
  - `totalSold`: Tracks the total number of tokens sold across all rounds.

- **Mappings**:
  - `rounds`: Maps round numbers to round parameters.
  - `referrals`: Maps referral codes to referral parameters.
  - `paymentTokens`: Maps payment token addresses to their authorization status.

- **Events**:
  - `SetRound`: Emitted when round parameters are set.
  - `RoundStarted`: Emitted when a new round starts.
  - `BuyTokens`: Emitted when tokens are purchased.
  - `Withdraw`: Emitted when funds are withdrawn.
  - `AddPaymentToken`: Emitted when a payment token is added.
  - `RemovePaymentToken`: Emitted when a payment token is removed.

- **Modifiers**:
  - `roundIsActive`: Ensures that the current presale round is active.
  
- **Functions**:
  - **Constructor**: Initializes the contract with the owner and a list of payment tokens.
  - **Core Functions**:
    - `setRound`: Sets parameters for a presale round.
    - `forceSetRound`: Sets parameters for a presale round even if it has already started.
    - `startNextRound`: Starts the next presale round.
    - `buyTokens`: Allows users to buy tokens in the current round using specified payment tokens.
    - `withdraw`: Allows the owner to withdraw funds from the contract.

#### Usage

1. **Initialization**: Deploy the Presale contract with the owner address and a list of payment tokens.

2. **Setting Rounds**: Set parameters for presale rounds using `setRound` or `forceSetRound` functions.

3. **Starting Rounds**: Start the presale rounds sequentially using the `startNextRound` function.

4. **Buying Tokens**: Users can buy tokens in the current round by calling the `buyTokens` function with the desired amount, referral code, and payment token address.

5. **Withdrawing Funds**: The owner can withdraw funds from the contract using the `withdraw` function.

6. **Adding/Removing Payment Tokens**: The owner can add or remove payment tokens using the `addPaymentToken` and `removePaymentToken` functions.

7. **Pausing and Unpausing**: The owner can pause and unpause the contract using the `pause` and `unpause` functions, respectively.

#### Security Considerations

- Ensure that the payment tokens used are authorized and adhere to the contract's requirements.
- Validate round parameters to prevent incorrect configuration.
- Use caution when modifying round parameters and pausing/unpausing the contract to avoid disrupting ongoing presale activities.

## Interface Specifications

**Inherits:**
ERC20, Ownable, Pausable


### State Variables
#### PERCENTAGE_RATE
Percentage rate: 100% = 10000 for 2 decimal places


```solidity
uint256 public constant PERCENTAGE_RATE = 10_000;
```


#### currentRound
Current round index


```solidity
uint8 public currentRound;
```


#### totalSold
Total amount of tokens sold at all rounds


```solidity
uint256 public totalSold;
```


#### rounds
Mapping of round number to round parameters


```solidity
mapping(uint8 roundId => Round round) public rounds;
```


#### referrals
Mapping of referral code to referral parameters


```solidity
mapping(uint8 referralId => Referral referral) public referrals;
```


#### paymentTokens
Mapping of payment tokens to their status


```solidity
mapping(address token => bool allowed) public paymentTokens;
```


### Functions
#### roundIsActive


```solidity
modifier roundIsActive();
```

#### constructor

Constructor


```solidity
constructor(address _owner, address[] memory _paymentTokens) Ownable(_owner) ERC20("TEAPresale", "TPS");
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`||
|`_paymentTokens`|`address[]`|List of payment tokens|


#### getRoundEnd

Returns the end time of the current round


```solidity
function getRoundEnd() public view returns (uint256);
```

#### getPrice

Returns the price of a token in the current round


```solidity
function getPrice() public view returns (uint256);
```

#### getRoundSize

Returns the size of the current round


```solidity
function getRoundSize() public view returns (uint256);
```

#### getRoundSold

Returns the amount of tokens sold in the current round


```solidity
function getRoundSold() public view returns (uint256);
```

#### pause

Pauses the contract


```solidity
function pause() public onlyOwner;
```

#### unpause

Unpauses the contract


```solidity
function unpause() public onlyOwner;
```

#### addPaymentToken

Adds a token to the list of payment tokens


```solidity
function addPaymentToken(address token) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the token to add|


#### removePaymentToken

Removes a token from the list of payment tokens


```solidity
function removePaymentToken(address token) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the token to remove|


#### _setRound

Sets round parameters for the presale

*Used internally by setRound and forceSetRound*


```solidity
function _setRound(uint8 round, uint256 startTime, uint256 duration, uint256 size, uint256 price) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`round`|`uint8`|Round index|
|`startTime`|`uint256`|Start time of the round|
|`duration`|`uint256`|Duration of the round|
|`size`|`uint256`|Amount of tokens sold in the round|
|`price`|`uint256`|Price of a token in the round|


#### setRound

Sets round parameters for the presale


```solidity
function setRound(uint8 round, uint256 startTime, uint256 duration, uint256 size, uint256 price) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`round`|`uint8`|Round index|
|`startTime`|`uint256`|Start time of the round|
|`duration`|`uint256`|Duration of the round|
|`size`|`uint256`|Amount of tokens sold in the round|
|`price`|`uint256`|Price of a token in the round in percentage (1% = 100)|


#### forceSetRound

Sets round parameters for the presale

*Used in case the round has already started*


```solidity
function forceSetRound(
    uint8 round,
    uint256 startTime,
    uint256 duration,
    uint256 size,
    uint256 price
)
    public
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`round`|`uint8`|Round index|
|`startTime`|`uint256`|Start time of the round|
|`duration`|`uint256`|Duration of the round|
|`size`|`uint256`|Amount of tokens sold in the round|
|`price`|`uint256`|Price of a token in the round|


#### startNextRound

Starts the next round


```solidity
function startNextRound() public onlyOwner;
```

#### buyTokens

Used to buy tokens in the current round


```solidity
function buyTokens(uint256 amount, uint8 referral, address tokenAddress) public whenNotPaused roundIsActive;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of tokens to buy|
|`referral`|`uint8`|Referral code|
|`tokenAddress`|`address`|Address of the payment token|


#### withdraw

Withdraws the balance of the contract


```solidity
function withdraw(address paymentToken) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`paymentToken`|`address`|Address of the token to withdraw|


### Events
#### SetRound
Event emitted when a round is set


```solidity
event SetRound(uint8 indexed round, uint256 startTime, uint256 duration, uint256 size, uint256 price);
```

#### RoundStarted
Event emitted when a round is started


```solidity
event RoundStarted(uint8 indexed round);
```

#### BuyTokens
Event emitted when tokens are bought


```solidity
event BuyTokens(address indexed buyer, uint256 amount, uint8 referral);
```

#### Withdraw
Event emitted when tokens are withdrawn


```solidity
event Withdraw(address indexed owner, address token, uint256 amount);
```

#### AddPaymentToken
Event emitted when a payment token is added


```solidity
event AddPaymentToken(address indexed token);
```

#### RemovePaymentToken
Event emitted when a payment token is removed


```solidity
event RemovePaymentToken(address indexed token);
```

### Errors
#### RoundAlreadyExists
Errors


```solidity
error RoundAlreadyExists(uint8 round);
```

#### RoundAlreadyStarted

```solidity
error RoundAlreadyStarted(uint8 round);
```

#### PreviousRoundActive

```solidity
error PreviousRoundActive(uint8 round);
```

#### RoundNotStarted

```solidity
error RoundNotStarted(uint8 round);
```

#### RoundFinished

```solidity
error RoundFinished(uint8 round);
```

#### RoundNotSet

```solidity
error RoundNotSet(uint8 round);
```

#### NotEnoughTokensLeft

```solidity
error NotEnoughTokensLeft(uint8 round, uint256 amount, uint256 available);
```

#### PaymentFailed

```solidity
error PaymentFailed(address from, address to, uint256 amount);
```

#### PaymentTokenNotAuthorized

```solidity
error PaymentTokenNotAuthorized(address token);
```

#### WithdrawFailed

```solidity
error WithdrawFailed();
```

### Structs
#### Round
Round parameters


```solidity
struct Round {
    uint256 startTime;
    uint256 duration;
    uint256 size;
    uint256 price;
    uint256 sold;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`startTime`|`uint256`|Start time of the round|
|`duration`|`uint256`|Duration of the round|
|`size`|`uint256`|Amount of tokens sold in the round|
|`price`|`uint256`|Price of a token in the round|
|`sold`|`uint256`|Amount of tokens sold in the round|

#### Referral
Referral parameters


```solidity
struct Referral {
    uint256 amountSold;
    uint256 numOfReferrals;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`amountSold`|`uint256`|Amount of tokens sold by the referral|
|`numOfReferrals`|`uint256`|Number of referrals made by the referral|



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
