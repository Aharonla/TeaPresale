// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";

contract PresaleScript is Script {
    function setUp() public {
        console2.log("PresaleScript.setUp");
    }

    function run() public {
        vm.broadcast();
    }
}
