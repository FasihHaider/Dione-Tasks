// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../../src/task3/Staking.sol";

contract StakingScript is Script {
    
    Staking public staking;
    address stakingToken;
    address rewardToken;
    address owner;
    
    function setUp() public {
        stakingToken = 0xc23589E3B653471e8cF0B6d5Dd7e231Bf98bE77c; // Beta Two Token
        rewardToken = 0xA26FC2342416AA625fc5a06D4657eb63372E1898; // New Alpha One Token
        owner = 0x4c61dfc1DBaB707B3b4bf87cb35C60B25D3CCC66;
    }

    function run() public {
        vm.startBroadcast();

        staking = new Staking(stakingToken, rewardToken, owner);

        vm.stopBroadcast();
    }
}
