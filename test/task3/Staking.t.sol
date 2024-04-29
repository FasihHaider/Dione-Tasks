// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../src/task3/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** uint256(decimals()));
    }
}

contract StakingTest is Test {
    bytes32 internal nextAddress = keccak256("User Address Seed");
    
    Staking staking;
    MockToken stakingToken;
    MockToken rewardToken;
    
    address owner;
    address user;

    function getNewAddress() private returns (address) {
        address newAddress = address(uint160(uint256(nextAddress)));
        nextAddress = keccak256(abi.encodePacked(nextAddress));
        return newAddress;
    }

    function setUp() public {
        owner = getNewAddress();
        user = getNewAddress();

        vm.startPrank(owner);

        stakingToken = new MockToken("Staking Token", "STK");
        rewardToken = new MockToken("Reward Token", "RWD");
        staking = new Staking(address(stakingToken), address(rewardToken), owner);

        stakingToken.transfer(user, 1000 * 10 ** stakingToken.decimals());
        rewardToken.transfer(address(staking), 1000* 10 ** rewardToken.decimals());
        
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(address(staking.stakingToken()), address(stakingToken));
        assertEq(address(staking.rewardToken()), address(rewardToken));
    }

    function testStake() public {
        uint256 amount = 100 * 10 ** 18;
        uint256 duration = 60 minutes;

        uint256 userStakingOldBalance = stakingToken.balanceOf(user);

        vm.startPrank(user);
        stakingToken.approve(address(staking), amount);
        staking.stake(amount, duration);
        vm.stopPrank();

        Staking.Stake memory stakeRecord = staking.getStakeRecord(user);
        assertEq(amount, stakeRecord.amount);
        assertEq(stakingToken.balanceOf(user), userStakingOldBalance - amount);
    }

    function testUnstake() public {
        uint256 duration = 60 minutes;

        testStake();

        vm.warp(block.timestamp + duration + 1);

        uint256 userRewardOldBalance = rewardToken.balanceOf(user);
        uint256 userStakingOldBalance = stakingToken.balanceOf(user);

        vm.startPrank(user);
        staking.unstake();
        vm.stopPrank();

        Staking.Stake memory stakeRecord = staking.getStakeRecord(user);
        assertEq(stakeRecord.amount, stakingToken.balanceOf(user) - userStakingOldBalance);
        assertEq(stakeRecord.reward, rewardToken.balanceOf(user) - userRewardOldBalance);
        assertEq(stakeRecord.isClaimed, true);
    }

    function testFailStakeSameUserTwice() public {
        uint256 amount = 100 * 10 ** 18;
        uint256 duration = 60 minutes;

        testStake();

        vm.startPrank(user);
        stakingToken.approve(address(staking), amount);
        staking.stake(amount, duration);
        vm.stopPrank();

    }

    function testFailClaimBeforeTime() public {
        uint256 duration = 60 minutes;
        
        testStake();

        vm.warp(block.timestamp + duration - 1);

        vm.startPrank(user);
        staking.unstake();
        vm.stopPrank();
    }
}
