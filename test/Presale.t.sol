// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Presale} from "../src/Presale.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";


contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 10**18);
    }
}

contract PresaleTest is Test {

    error EnforcedPause();

    Presale public presale;
    Token public usdt;
    Token public usdc;
    function setUp() public virtual {
        address[] memory tokens = new address[](2);
        usdt = new Token("USDT", "USDT");
        usdc = new Token("USDC", "USDC");
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        presale = new Presale(address(this), tokens);
    }

    function test_constructor() public {
        assertEq(presale.owner(), address(this));
        assertEq(presale.paused(), false);
        assertEq(presale.currentRound(), 0);
        assertEq(presale.PERCENTAGE_RATE(), 10**4);
        assertEq(presale.paymentTokens(usdt), true);
        assertEq(presale.paymentTokens(usdc), true);
    }

    function test_GetRoundEnd() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        assertEq(presale.getRoundEnd(), block.timestamp + 3600);
    }

    function test_GetPrice() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        assertEq(presale.getPrice(), 100);
    }

    function test_GetRoundSize() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        assertEq(presale.getRoundSize(), 10**6);
    }

    function test_GetRoundSold(uint256 amountBought) public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        uint256 PERCENTAGE_RATE = presale.PERCENTAGE_RATE();
        vm.assume(amountBought <= 10**6);
        presale.startNextRound();
        uint256 price = presale.getPrice();
        usdt.approve(address(presale), amountBought * price / PERCENTAGE_RATE);
        presale.buyTokens(amountBought, 0, address(usdt));
        assertEq(presale.getRoundSold(), amountBought);
    }

    function test_Pause() public {
        vm.expectEmit(true, true, true, true);
        emit Pausable.Paused(address(this));
        presale.pause();
        assertEq(presale.paused(), true);
    }

    function test_Pause_RevertWhen_notAdmin(address notOwner) public {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.pause();
    }

    function test_Unpause() public {
        presale.pause();
        vm.expectEmit(true, true, true, true);
        emit Pausable.Unpaused(address(this));
        presale.unpause();
        assertEq(presale.paused(), false);
    }

    function test_Unpause_RevertWhen_notAdmin(address notOwner) public {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.unpause();
    }

    function test_AddPaymentToken() public {
        Token token = new Token("TKN", "TKN");
        vm.expectEmit(true, true, true, true);
        emit Presale.AddPaymentToken(address(token));
        presale.addPaymentToken(address(token));
        assertEq(presale.paymentTokens(token), true);
        }

    function test_AddPaymentToken_RevertWhen_notAdmin(address notOwner) public {
        Token token = new Token("TKN", "TKN");
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.addPaymentToken(address(token));
    }

    function test_RemovePaymentToken() public {
        Token token = new Token("TKN", "TKN");
        presale.addPaymentToken(address(token));
        assertEq(presale.paymentTokens(token), true);
        vm.expectEmit(true, true, true, true);
        emit Presale.RemovePaymentToken(address(token));
        presale.removePaymentToken(address(token));
        assertEq(presale.paymentTokens(token), false);
    }

    function test_RemovePaymentToken_RevertWhen_notAdmin(address notOwner) public {
        Token token = new Token("TKN", "TKN");
        presale.addPaymentToken(address(token));
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.removePaymentToken(address(token));
    }

    function test_SetRound() public {
        vm.expectEmit(true, true, true, true);
        emit Presale.SetRound(1, block.timestamp, 3600, 10**6, 100);
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        (
            uint256 startTime, 
            uint256 duration, 
            uint256 size, 
            uint256 price, 
            uint256 sold
        ) = presale.rounds(1);
        assertEq(startTime, block.timestamp);
        assertEq(duration, 3600);
        assertEq(size, 10**6);
        assertEq(price, 100);
        assertEq(sold, 0);
        assertEq(presale.currentRound(), 0);
    }

    function test_SetRound_RevertWhen_RoundAlreadyExists() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        vm.expectRevert(abi.encodeWithSelector(Presale.RoundAlreadyExists.selector, 1));
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
    }


    function test_SetRound_RevertWhen_notAdmin(address notOwner) public {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
    }

    function test_ForceSetRound() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        vm.expectRevert(abi.encodeWithSelector(Presale.RoundAlreadyExists.selector, 1));
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        vm.expectEmit(true, true, true, true);
        emit Presale.SetRound(1, block.timestamp, 3600, 10**6, 100);
        presale.forceSetRound(1, block.timestamp, 3600, 10**6, 100);
        (
            uint256 startTime, 
            uint256 duration, 
            uint256 size, 
            uint256 price, 
            uint256 sold
        ) = presale.rounds(1);
        assertEq(startTime, block.timestamp);
        assertEq(duration, 3600);
        assertEq(size, 10**6);
        assertEq(price, 100);
        assertEq(sold, 0);
        assertEq(presale.currentRound(), 0);
    }

    function test_ForceSetRound_RevertWhen_RoundAlreadyStarted() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**8);
        presale.buyTokens(10**6, 0, address(usdt));
        vm.expectRevert(abi.encodeWithSelector(Presale.RoundAlreadyStarted.selector, 1));
        presale.forceSetRound(1, block.timestamp, 3600, 10**6, 100);
    }

    function test_ForceSetRound_RevertWhen_notAdmin(address notOwner) public {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.forceSetRound(1, block.timestamp, 3600, 10**6, 100);
    }

    function test_StartNextRound() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        vm.expectEmit(true, false, false, false);
        emit Presale.RoundStarted(1);
        presale.startNextRound();
        assertEq(presale.currentRound(), 1);
    }

    function test_StartNextRound_RevertWhen_PreviousRoundActive() public {
        uint256 endTime = block.timestamp + 3600;
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        vm.warp(endTime);
        presale.setRound(2, block.timestamp, 3600, 10**6, 100);
        vm.expectRevert(abi.encodeWithSelector(Presale.PreviousRoundActive.selector, 1));
        presale.startNextRound();
    }

    function test_StartNextRound_RevertWhen_notAdmin() public {
        vm.prank(address(0));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
        presale.startNextRound();
    }

    function test_StartNextRound_AfterPreviousRoundEnded() public {
        uint256 endTime = block.timestamp + 3600;
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        vm.warp(endTime + 1);
        presale.setRound(2, block.timestamp, 3600, 10**6, 100);
        vm.expectEmit(true, false, false, false);
        emit Presale.RoundStarted(2);
        presale.startNextRound();
        assertEq(presale.currentRound(), 2);
    }

    function test_BuyTokens() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**4);
        uint256 ptBalanceBefore = usdt.balanceOf(address(this));
        uint256 ptBalancePresaleBefore = usdt.balanceOf(address(presale));
        uint256 balanceBefore = presale.balanceOf(address(this));
        assertEq(balanceBefore, 0);
        vm.expectEmit(true, true, true, true);
        emit Presale.BuyTokens(address(this), 10**6, 0);
        presale.buyTokens(10**6, 0, address(usdt));
        (, , , , uint256 sold) = presale.rounds(1);
        assertEq(sold, 10**6);
        uint256 balanceAfter = presale.balanceOf(address(this));
        assertEq(balanceAfter, 10**6);
        uint256 ptBalanceAfter = usdt.balanceOf(address(this));
        assertEq(ptBalanceBefore - ptBalanceAfter, 10**4);
        uint256 ptBalancePresaleAfter = usdt.balanceOf(address(presale));
        assertEq(ptBalancePresaleAfter - ptBalancePresaleBefore, 10**4);
    }

    function test_BuyTokens_RevertWhen_NotEnoughTokensLeft() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**8);
        presale.buyTokens(10**6, 0, address(usdt));
        vm.expectRevert(abi.encodeWithSelector(Presale.NotEnoughTokensLeft.selector, 1, 1, 0));
        presale.buyTokens(1, 0, address(usdt));
    }

    function test_BuyTokens_RevertWhen_Paused() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        presale.pause();
        usdt.approve(address(presale), 10**8);
        vm.expectRevert(abi.encodeWithSelector(EnforcedPause.selector));
        presale.buyTokens(10**6, 0, address(usdt));
    }

    function test_BuyTokens_RevertWhen_RoundNotStarted() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**8);
        vm.warp(block.timestamp - 10);
        vm.expectRevert(abi.encodeWithSelector(Presale.RoundNotStarted.selector, 1));
        presale.buyTokens(10**6, 0, address(usdt));
    }

    function test_BuyTokens_RevertWhen_RoundFinished() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**8);
        vm.warp(block.timestamp + 3601);
        vm.expectRevert(abi.encodeWithSelector(Presale.RoundFinished.selector, 1));
        presale.buyTokens(10**6, 0, address(usdt));
    }

    function test_BuyTokens_RevertWhen_PaymentTokenNotAdded() public {
        Token token = new Token("TKN", "TKN");
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**8);
        vm.expectRevert(abi.encodeWithSelector(Presale.PaymentTokenNotAuthorized.selector, address(token)));
        presale.buyTokens(10**6, 0, address(token));
    }

    function test_Withdraw() public {
        presale.setRound(1, block.timestamp, 3600, 10**6, 100);
        presale.startNextRound();
        usdt.approve(address(presale), 10**4);
        presale.buyTokens(10**6, 0, address(usdt));
        uint256 ptBalanceBefore = usdt.balanceOf(address(this));
        uint256 ptBalancePresaleBefore = usdt.balanceOf(address(presale));
        vm.expectEmit(true, false, false, false);
        emit Presale.Withdraw(address(this), 10**4);
        presale.withdraw(address(usdt));
        uint256 ptBalanceAfter = usdt.balanceOf(address(this));
        assertEq(ptBalanceAfter - ptBalanceBefore, 10**4);
        uint256 ptBalancePresaleAfter = usdt.balanceOf(address(presale));
        assertEq(ptBalancePresaleBefore - ptBalancePresaleAfter, 10**4);
    }

    function test_Withdraw_RevertWhen_notAdmin(address notOwner) public {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        presale.withdraw(address(usdt));
    }
}
