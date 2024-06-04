// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import { Presale } from "../src/Presale.sol";

contract PresaleScript is Script {
    function run() external returns(address presaleAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.envAddress("MAINNET_OWNER_ADDRESS");
        address usdcAddress = vm.envAddress("MAINNET_USDC_ADDRESS");
        address usdtAddress = vm.envAddress("MAINNET_USDT_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);
        address[] memory tokens = new address[](2);
        tokens[0] = usdtAddress;
        tokens[1] = usdcAddress;
        Presale presale = new Presale(ownerAddress, tokens);

        vm.stopBroadcast();
        console2.log(address(presale));
        return (address(presale));
    }
}
