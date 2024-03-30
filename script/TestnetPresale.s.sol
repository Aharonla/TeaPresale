// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import { Presale } from "../src/Presale.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 10**18);
    }
}

contract PresaleScript is Script {
    function run() external returns(address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Token usdt = new Token("USDT", "USDT");
        Token usdc = new Token("USDC", "USDC");
        address[] memory tokens = new address[](2);
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        Presale presale = new Presale(tokens);

        vm.stopBroadcast();
        console2.log(address(presale));
        return address(presale);
    }
}
