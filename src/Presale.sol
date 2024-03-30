// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Presale is ERC20, Ownable, Pausable {
    error RoundAlreadyExists(uint8 round);
    error RoundAlreadyStarted(uint8 round);
    error PreviousRoundActive(uint8 round);
    error RoundNotStarted(uint8 round);
    error RoundFinished(uint8 round);
    error NotEnoughTokensLeft(uint8 round, uint256 amount, uint256 available);
    error PaymentFailed(address from, address to, uint256 amount);
    error PaymentTokenNotAuthorized(address token);

    event SetRound(uint8 indexed round, uint256 startTime, uint256 duration, uint256 size, uint256 price);
    event RoundStarted(uint8 indexed round);
    event BuyTokens(address indexed buyer, uint256 amount, uint8 referral);
    event Withdraw(address indexed owner, uint256 amount);
    event AddPaymentToken(address indexed token);
    event RemovePaymentToken(address indexed token);

    modifier roundIsActive() {
        if (rounds[currentRound].startTime > block.timestamp) {
            revert RoundNotStarted(currentRound);
        }
        if (rounds[currentRound].startTime + rounds[currentRound].duration < block.timestamp) {
            revert RoundFinished(currentRound);
        }
        _;}

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

    uint8 public currentRound;
    uint256 public totalSold;

    /// @notice Mapping of round number to round parameters
    mapping(uint8 roundId => Round round) public rounds;

    /// @notice Mapping of referral code to referral parameters
    mapping(uint8 referralId  => Referral referral) public referrals;

    /// @notice Mapping of payment tokens to their status
    mapping(ERC20 token => bool allowed) public paymentTokens;

    /// @notice Constructor
    /// @param _paymentTokens List of payment tokens
    constructor(address[] memory _paymentTokens) Ownable(_msgSender()) ERC20("TEAPresale", "TPS") {
        for(uint256 i = 0; i < _paymentTokens.length; i++) {
            paymentTokens[ERC20(_paymentTokens[i])] = true;
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
    /// @param _token Address of the token to add
    function addPaymentToken(address _token) public onlyOwner {
        paymentTokens[ERC20(_token)] = true;
        emit AddPaymentToken(_token);
    }

    /// @notice Removes a token from the list of payment tokens
    /// @param _token Address of the token to remove
    function removePaymentToken(address _token) public onlyOwner {
        paymentTokens[ERC20(_token)] = false;
        emit RemovePaymentToken(_token);
    }

    /// @notice Sets round parameters for the presale
    /// @dev Used internally by setRound and forceSetRound
    /// @param _round Round index
    /// @param _startTime Start time of the round
    /// @param _duration Duration of the round
    /// @param _size Amount of tokens sold in the round
    /// @param _price Price of a token in the round
    function _setRound(
        uint8 _round, 
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _size,
        uint256 _price
    ) internal {
        rounds[_round] = Round(_startTime, _duration, _size, _price, 0);
        emit SetRound(_round, _startTime, _duration, _size, _price);
    }

    /// @notice Sets round parameters for the presale
    /// @param _round Round index
    /// @param _startTime Start time of the round
    /// @param _duration Duration of the round
    /// @param _size Amount of tokens sold in the round
    /// @param _price Price of a token in the round
    function setRound(
        uint8 _round,
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _size, 
        uint256 _price
    ) public onlyOwner {
        if(rounds[_round].size != 0) {
            revert RoundAlreadyExists(_round);
        }
        _setRound(_round, _startTime, _duration, _size, _price);
    }

    /// @notice Sets round parameters for the presale
    /// @dev Used in case the round has already started
    /// @param _round Round index
    /// @param _startTime Start time of the round
    /// @param _duration Duration of the round
    /// @param _size Amount of tokens sold in the round
    /// @param _price Price of a token in the round
    function forceSetRound(
        uint8 _round,
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _size,
        uint256 _price
    ) public onlyOwner {
        if(rounds[_round].sold != 0) {
            revert RoundAlreadyStarted(_round);
        }
        _setRound(_round, _startTime, _duration, _size, _price);
    }

    /// @notice Starts the next round
    function startNextRound() public onlyOwner {
        if(rounds[currentRound].startTime + rounds[currentRound].duration >= block.timestamp) {
            revert PreviousRoundActive(currentRound);
        } else {
            currentRound++;
            emit RoundStarted(currentRound);
        }
    }

    /// @notice Used to buy tokens in the current round
    /// @param _amount Amount of tokens to buy
    /// @param _referral Referral code
    /// @param _paymentToken Address of the payment token
    function buyTokens(uint256 _amount, uint8 _referral, address _paymentToken) 
    public 
    payable 
    whenNotPaused 
    roundIsActive 
    {
        if (rounds[currentRound].sold + _amount > rounds[currentRound].size) {
            revert NotEnoughTokensLeft(currentRound, _amount, rounds[currentRound].size - rounds[currentRound].sold);
        }
        ERC20 paymentToken;
        if(_paymentToken == address(0)) {
            revert PaymentTokenNotAuthorized(_paymentToken);
        } else {
            paymentToken = ERC20(_paymentToken);
        }
        uint256 paymentAmount = _amount * rounds[currentRound].price;
        rounds[currentRound].sold += _amount;
        totalSold += _amount;
        referrals[_referral].amountSold += _amount;
        referrals[_referral].numOfReferrals++;
        _mint(_msgSender(), _amount);
        bool success = paymentToken.transferFrom(_msgSender(),address(this), paymentAmount);
        if(!success) {
            revert PaymentFailed(_msgSender(), address(this), paymentAmount);
        }
        emit BuyTokens(_msgSender(), _amount, _referral);
    }

    /// @notice Withdraws the balance of the contract
    /// @param paymentToken Address of the token to withdraw
    function withdraw(address paymentToken) public onlyOwner {
        emit Withdraw(_msgSender(), ERC20(paymentToken).balanceOf(address(this)));
        ERC20(paymentToken).transfer(_msgSender(), ERC20(paymentToken).balanceOf(address(this)));
    }
}
