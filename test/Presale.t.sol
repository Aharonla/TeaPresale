// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Presale} from "../src/Presale.sol";

contract CounterTest is Test {

    Presale public presale;
    function setUp() public {
        presale = new Presale(address(this));
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
}
