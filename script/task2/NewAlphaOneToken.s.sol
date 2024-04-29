// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../../src/task2/NewAlphaOneToken.sol";

contract NewAlphaOneTokenScript is Script {
    
    NewAlphaOneToken public newAlphaOneToken;

    address _oldToken;
    address owner;
    
    function setUp() public {
        _oldToken = 0x8bA9aB84F07971d9E2980c3029714378255834Fe;
        owner = 0x4c61dfc1DBaB707B3b4bf87cb35C60B25D3CCC66;
    }

    function run() public {
        vm.startBroadcast();

        newAlphaOneToken = new NewAlphaOneToken(_oldToken, owner);

        vm.stopBroadcast();
    }
}
