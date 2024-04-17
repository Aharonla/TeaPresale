// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import { Presale } from "../src/Presale.sol";
// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StartRound is Script {
    address public presaleAddress;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        presaleAddress = vm.envAddress("PRESALE_ADDRESS");
        Presale presale = Presale(presaleAddress);
        /// @notice Set round 1 with 1 million tokens, 0.07 eth per token, and 3 days duration
        presale.setRound(1, block.timestamp, 3 days, 10**6 * 1 ether, 700);
        presale.startNextRound();
        vm.stopBroadcast();
    }
}