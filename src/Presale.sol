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

    event SetRound(uint8 indexed round, uint256 startTime, uint256 duration, uint256 size, uint256 price);
    event RoundStarted(uint8 indexed round);

    modifier roundIsActive() {
        if (rounds[currentRound].startTime > block.timestamp) {
            revert RoundNotStarted(currentRound);
        }
        if (rounds[currentRound].startTime + rounds[currentRound].duration < block.timestamp) {
            revert RoundFinished(currentRound);
        }
        _;}

    /// @notice Round parameters
    struct Round {
        uint256 startTime;
        uint256 duration;
        uint256 size;
        uint256 price;
        uint256 sold;
    }

    struct referral {
        uint256 amountSold;
        uint256 numOfReferrals;
    }

    uint8 public currentRound;
    uint256 public totalSold;
    ERC20 public paymentToken;

    /// @notice Mapping of round number to round parameters
    mapping(uint8 roundId => Round round) public rounds;

    mapping(uint8 => referral) public referrals;


    constructor(address _paymentToken) Ownable(_msgSender()) ERC20("TEAPresale", "TPS") {
        paymentToken = ERC20(_paymentToken);
    }

    function getRoundEnd() public view returns (uint256) {
        return rounds[currentRound].startTime + rounds[currentRound].duration;
    }

    function getPrice() public view returns (uint256) {
        return rounds[currentRound].price;
    }

    function getRoundSize() public view returns (uint256) {
        return rounds[currentRound].size;
    }

    function getRoundSold() public view returns (uint256) {
        return rounds[currentRound].sold;
    }


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

    function startNextRound() public onlyOwner {
        if(rounds[currentRound].startTime + rounds[currentRound].duration >= block.timestamp) {
            revert PreviousRoundActive(currentRound);
        } else {
            currentRound++;
            emit RoundStarted(currentRound);
        }
    }

    function buyTokens(uint256 _amount, uint8 _referral) 
    public 
    payable 
    whenNotPaused 
    roundIsActive 
    {
        if (rounds[currentRound].sold + _amount > rounds[currentRound].size) {
            revert NotEnoughTokensLeft(currentRound, _amount, rounds[currentRound].size - rounds[currentRound].sold);
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
    }

    function withdraw() public onlyOwner {
        paymentToken.transfer(_msgSender(), paymentToken.balanceOf(address(this)));
    }

}
