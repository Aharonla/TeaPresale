/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Presale } from "./Presale.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Claim is Ownable{
    Presale public presale;
    IERC20 public immutable teaToken;
    mapping(address claimer => uint256 amountClaimed) public tokensClaimed;

    event Claimed(address indexed user, uint256 amount);

    error ClaimFailed();

    constructor(address _presale, address _teaToken) Ownable(_msgSender()) {
        presale = Presale(_presale);
        teaToken = IERC20(_teaToken);
    }

    function claim() public {
        uint256 amount = presale.balanceOf(msg.sender) - tokensClaimed[msg.sender];
        tokensClaimed[msg.sender] += amount;
        emit Claimed(msg.sender, amount);
        bool success =  teaToken.transfer(msg.sender, amount);
        if (!success) {
            revert ClaimFailed();
        }
    }

    function setPresale(address presaleAddress) public onlyOwner {
        presale = Presale(presaleAddress);
    }
}