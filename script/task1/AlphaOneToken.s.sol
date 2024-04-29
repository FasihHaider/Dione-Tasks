// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../../src/task1/AlphaOneToken.sol";

contract AlphaOneTokenScript is Script {
    
    AlphaOneToken public alphaOneToken;
    address owner;
    
    function setUp() public {
        owner = 0x4c61dfc1DBaB707B3b4bf87cb35C60B25D3CCC66;
    }

    function run() public {
        vm.startBroadcast();

        alphaOneToken = new AlphaOneToken(owner);

        vm.stopBroadcast();
    }
}
