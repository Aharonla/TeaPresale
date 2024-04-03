// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import { Presale } from "../src/Presale.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SendUSDC is Script {
    ERC20 public usdt;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        usdt = ERC20(usdcAddress);
        address developer = vm.envAddress("DEVELOPER");
        /// @notice Set round 1 with 1 million tokens, 0.07 eth per token, and 3 days duration
        usdt.transfer(developer, 10**6 * 1 ether);
        vm.stopBroadcast();
    }
}