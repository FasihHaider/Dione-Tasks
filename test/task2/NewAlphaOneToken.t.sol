// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../src/task1/AlphaOneToken.sol";
import "../../src/task2/NewAlphaOneToken.sol";

contract NewAlphaOneTokenTest is Test {
    bytes32 internal nextAddress = keccak256("User Address Seed");

    AlphaOneToken oldToken;
    NewAlphaOneToken newToken;
    
    address owner;
    address user1;
    address user2;
    address oldTokenReceiver;

    function getNewAddress() private returns (address) {
        address newAddress = address(uint160(uint256(nextAddress)));
        nextAddress = keccak256(abi.encodePacked(nextAddress));
        return newAddress;
    }

    function setUp() public {
        owner = getNewAddress();
        user1 = getNewAddress();
        user2 = getNewAddress();
        oldTokenReceiver = getNewAddress();

        oldToken = new AlphaOneToken(owner);
        newToken = new NewAlphaOneToken(address(oldToken), owner);

        vm.startPrank(owner);
        oldToken.setTransferTax(0);
        oldToken.transfer(user1, 1000 * 10 ** oldToken.decimals());
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(newToken.balanceOf(owner), 1_000_000 * 10 ** newToken.decimals());
        assertEq(address(newToken.oldToken()), address(oldToken));
    }

    function testMigrateWithoutTax() public {
        uint256 oldBalanceUser1 = oldToken.balanceOf(user1);
        uint256 migrateAmount = 200 * 10 ** oldToken.decimals();

        vm.startPrank(user1);
        oldToken.approve(address(newToken), migrateAmount * 2);
        newToken.migrateWithoutTax(migrateAmount);
        vm.stopPrank();

        assertEq(oldToken.balanceOf(user1), oldBalanceUser1 - migrateAmount, "Old token balance should decrease");
        assertEq(newToken.balanceOf(user1), migrateAmount, "New token balance should match migrated amount");
        assertEq(oldToken.balanceOf(address(newToken)), migrateAmount, "Old tokens should be transferred to new token contract");

        vm.startPrank(owner);
        newToken.setOldTokenReceiver(oldTokenReceiver);
        vm.stopPrank();

        oldBalanceUser1 = oldToken.balanceOf(user1);
        uint256 newBalanceUser1 = newToken.balanceOf(user1);
        
        vm.startPrank(user1);
        newToken.migrateWithoutTax(migrateAmount);
        vm.stopPrank();

        assertEq(oldToken.balanceOf(user1), oldBalanceUser1 - migrateAmount, "Old token balance should decrease");
        assertEq(newToken.balanceOf(user1), newBalanceUser1 + migrateAmount, "New token balance should match migrated amount");
        assertEq(oldToken.balanceOf(oldTokenReceiver), migrateAmount, "Old tokens should be transferred to old token receiver");
    }

    function testMigrateWithTax() public {
        uint256 oldBalanceUser1 = oldToken.balanceOf(user1);
        uint256 oldBalanceTaxReeciver = oldToken.balanceOf(oldToken.taxReceiver());
        uint256 migrateAmount = 200 * 10 ** oldToken.decimals();
        uint256 taxAmount = (migrateAmount * oldToken.transferTax()) / (100 * oldToken.TAX_DIVISOR());

        vm.startPrank(user1);
        oldToken.approve(address(newToken), migrateAmount * 2);
        newToken.migrateWithTax(migrateAmount);
        vm.stopPrank();

        assertEq(oldToken.balanceOf(user1), oldBalanceUser1 - migrateAmount, "Old token balance should decrease");
        assertEq(newToken.balanceOf(user1), migrateAmount - taxAmount, "New token balance should match migrated amount minus tax");
        assertEq(oldToken.balanceOf(address(newToken)), migrateAmount - taxAmount, "Old tokens should be transferred to new token contract");
        assertEq(oldToken.balanceOf(oldToken.taxReceiver()), oldBalanceTaxReeciver + taxAmount, "Tax amount should be transferred to tax receiver");

    }

}
