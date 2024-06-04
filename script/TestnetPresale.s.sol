// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import { Presale } from "../src/Presale.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 300 * 10**6 * 1 ether);
    }
}

contract PresaleScript is Script {
    function run() external returns(address presaleAddress, address usdtAddress, address usdcAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.envAddress("TESTNET_OWNER_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);
        Token usdt = new Token("USDT", "USDT");
        Token usdc = new Token("USDC", "USDC");
        address[] memory tokens = new address[](2);
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        Presale presale = new Presale(ownerAddress, tokens);

        vm.stopBroadcast();
        console2.log(address(presale));
        console2.log(address(usdt));
        console2.log(address(usdc));
        return (address(presale), address(usdt), address(usdc));
    }
}
