// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Presale is ERC20, Ownable, Pausable {
    using SafeERC20 for ERC20;

    /// @notice Round parameters
    /// @param startTime Start time of the round
    /// @param duration Duration of the round
    /// @param size Amount of tokens sold in the round
    /// @param price Price of a token in the round
    /// @param sold Amount of tokens sold in the round
    struct Round {
        uint256 startTime;
        uint256 duration;
        uint256 size;
        uint256 price;
        uint256 sold;
    }

    /// @notice Referral parameters
    /// @param amountSold Amount of tokens sold by the referral
    /// @param numOfReferrals Number of referrals made by the referral
    struct Referral {
        uint256 amountSold;
        uint256 numOfReferrals;
    }

    /// @notice Percentage rate: 100% = 10000 for 2 decimal places
    uint256 public constant PERCENTAGE_RATE = 10000;
    /// @notice Current round index
    uint8 public currentRound;
    /// @notice Total amount of tokens sold at all rounds
    uint256 public totalSold;

    /// @notice Mapping of round number to round parameters
    mapping(uint8 roundId => Round round) public rounds;
    /// @notice Mapping of referral code to referral parameters
    mapping(uint8 referralId  => Referral referral) public referrals;
    /// @notice Mapping of payment tokens to their status
    mapping(address token => bool allowed) public paymentTokens;

    /// @notice Event emitted when a round is set
    event SetRound(uint8 indexed round, uint256 startTime, uint256 duration, uint256 size, uint256 price);
    /// @notice Event emitted when a round is started
    event RoundStarted(uint8 indexed round);
    /// @notice Event emitted when tokens are bought
    event BuyTokens(address indexed buyer, uint256 amount, uint8 referral);
    /// @notice Event emitted when tokens are withdrawn
    event Withdraw(address indexed owner, address token, uint256 amount);
    /// @notice Event emitted when a payment token is added
    event AddPaymentToken(address indexed token);
    /// @notice Event emitted when a payment token is removed
    event RemovePaymentToken(address indexed token);

    /// @notice Errors
    error RoundAlreadyExists(uint8 round);
    error RoundAlreadyStarted(uint8 round);
    error PreviousRoundActive(uint8 round);
    error RoundNotStarted(uint8 round);
    error RoundFinished(uint8 round);
    error RoundNotSet(uint8 round);
    error NotEnoughTokensLeft(uint8 round, uint256 amount, uint256 available);
    error PaymentFailed(address from, address to, uint256 amount);
    error PaymentTokenNotAuthorized(address token);
    error WithdrawFailed();
    
    modifier roundIsActive() {
        if (rounds[currentRound].startTime > block.timestamp) {
            revert RoundNotStarted(currentRound);
        }
        if (rounds[currentRound].startTime + rounds[currentRound].duration < block.timestamp) {
            revert RoundFinished(currentRound);
        }
        _;}

    /// @notice Constructor
    /// @param _paymentTokens List of payment tokens
    constructor(address _owner, address[] memory _paymentTokens) Ownable(_owner) ERC20("TEAPresale", "TPS") {
        for(uint256 i = 0; i < _paymentTokens.length; i++) {
            if (_paymentTokens[i] == address(0)) {
                revert PaymentTokenNotAuthorized(_paymentTokens[i]);
            }
            paymentTokens[_paymentTokens[i]] = true;
            emit AddPaymentToken(_paymentTokens[i]);
        }
    }

    /// @notice Returns the end time of the current round
    function getRoundEnd() public view returns (uint256) {
        return rounds[currentRound].startTime + rounds[currentRound].duration;
    }

    /// @notice Returns the price of a token in the current round
    function getPrice() public view returns (uint256) {
        return rounds[currentRound].price;
    }

    /// @notice Returns the size of the current round
    function getRoundSize() public view returns (uint256) {
        return rounds[currentRound].size;
    }

    /// @notice Returns the amount of tokens sold in the current round
    function getRoundSold() public view returns (uint256) {
        return rounds[currentRound].sold;
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Adds a token to the list of payment tokens
    /// @param token Address of the token to add
    function addPaymentToken(address token) public onlyOwner {
        paymentTokens[token] = true;
        emit AddPaymentToken(token);
    }

    /// @notice Removes a token from the list of payment tokens
    /// @param token Address of the token to remove
    function removePaymentToken(address token) public onlyOwner {
        paymentTokens[token] = false;
        emit RemovePaymentToken(token);
    }

    /// @notice Sets round parameters for the presale
    /// @dev Used internally by setRound and forceSetRound
    /// @param round Round index
    /// @param startTime Start time of the round
    /// @param duration Duration of the round
    /// @param size Amount of tokens sold in the round
    /// @param price Price of a token in the round
    function _setRound(
        uint8 round, 
        uint256 startTime, 
        uint256 duration, 
        uint256 size,
        uint256 price
    ) internal {
        rounds[round] = Round(startTime, duration, size, price, 0);
        emit SetRound(round, startTime, duration, size, price);
    }

    /// @notice Sets round parameters for the presale
    /// @param round Round index
    /// @param startTime Start time of the round
    /// @param duration Duration of the round
    /// @param size Amount of tokens sold in the round
    /// @param price Price of a token in the round in percentage (1% = 100)
    function setRound(
        uint8 round,
        uint256 startTime, 
        uint256 duration, 
        uint256 size, 
        uint256 price
    ) public onlyOwner {
        if(rounds[round].size != 0) {
            revert RoundAlreadyExists(round);
        }
        _setRound(round, startTime, duration, size, price);
    }

    /// @notice Sets round parameters for the presale
    /// @dev Used in case the round has already started
    /// @param round Round index
    /// @param startTime Start time of the round
    /// @param duration Duration of the round
    /// @param size Amount of tokens sold in the round
    /// @param price Price of a token in the round
    function forceSetRound(
        uint8 round,
        uint256 startTime, 
        uint256 duration, 
        uint256 size,
        uint256 price
    ) public onlyOwner {
        if(rounds[round].sold != 0) {
            revert RoundAlreadyStarted(round);
        }
        _setRound(round, startTime, duration, size, price);
    }

    /// @notice Starts the next round
    function startNextRound() public onlyOwner {
        if(rounds[currentRound].startTime + rounds[currentRound].duration >= block.timestamp) {
            revert PreviousRoundActive(currentRound);
        }
        if(rounds[currentRound + 1].size == 0) {
            revert RoundNotSet(currentRound + 1);
        }
            currentRound++;
            emit RoundStarted(currentRound);
    }

    /// @notice Used to buy tokens in the current round
    /// @param amount Amount of tokens to buy
    /// @param referral Referral code
    /// @param tokenAddress Address of the payment token
    function buyTokens(uint256 amount, uint8 referral, address tokenAddress) 
    public 
    whenNotPaused 
    roundIsActive 
    {
        if (rounds[currentRound].sold + amount > rounds[currentRound].size) {
            revert NotEnoughTokensLeft(currentRound, amount, rounds[currentRound].size - rounds[currentRound].sold);
        }
        if(!paymentTokens[tokenAddress]) {
            revert PaymentTokenNotAuthorized(tokenAddress);
        }
        uint256 paymentAmount = amount * rounds[currentRound].price / PERCENTAGE_RATE;
        rounds[currentRound].sold += amount;
        totalSold += amount;
        referrals[referral].amountSold += amount;
        referrals[referral].numOfReferrals++;
        _mint(_msgSender(), amount);
        emit BuyTokens(_msgSender(), amount, referral);
        ERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), paymentAmount);
    }

    /// @notice Withdraws the balance of the contract
    /// @param paymentToken Address of the token to withdraw
    function withdraw(address paymentToken) public onlyOwner {
        emit Withdraw(_msgSender(), paymentToken, ERC20(paymentToken).balanceOf(address(this)));
        ERC20(paymentToken).safeTransfer(_msgSender(), ERC20(paymentToken).balanceOf(address(this)));
    }
}
