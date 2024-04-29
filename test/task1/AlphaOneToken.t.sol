// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/Task1/AlphaOneToken.sol";

contract AlphaOneTokenTest is Test {
    
    bytes32 internal nextAddress = keccak256(abi.encodePacked('user address'));
    
    AlphaOneToken token;
    address owner;    
    address user1;
    address user2;

    function getNewAddress() private returns (address payable) {
        address payable newAddress = payable(address(uint160(uint256(nextAddress))));
        nextAddress = keccak256(abi.encodePacked(nextAddress));
        return newAddress;
    }

    function setUp() public {
        owner = getNewAddress();
        user1 = getNewAddress();
        user2 = getNewAddress();

        token = new AlphaOneToken(owner);
    }

    function testInitialSetup() public {
        assertEq(token.balanceOf(owner), 1_000_000 * 10 ** token.decimals());
        assertEq(token.taxReceiver(), owner);
        assertEq(token.transferTax(), 500);
        assertEq(token.buySellTax(), 500);
    }

    function testTransferWithTax() public {
        uint256 amount = 100 * 10 ** token.decimals();
        
        vm.startPrank(owner);
        token.setTransferTax(0);
        token.transfer(user1, amount);
        token.setTransferTax(500);
        vm.stopPrank();

        uint256 taxReceiverInitialBalance = token.balanceOf(token.taxReceiver());
        uint256 taxAmount = (amount * token.transferTax()) / (100 * token.TAX_DIVISOR());

        vm.startPrank(user1);
        token.transfer(user2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(token.taxReceiver()), taxReceiverInitialBalance + taxAmount);
    }

    function testBuySellWithWhitelist() public {
        uint256 amount = 100 * 10 ** token.decimals();
        address dexAddress = getNewAddress();
        
        vm.startPrank(owner);
        token.setTransferTax(0);
        token.transfer(user1, amount);
        token.setWhitelist(dexAddress, true);
        token.setBuySellTax(200);
        vm.stopPrank();

        // sell case
        
        uint256 taxReceiverInitialBalance = token.balanceOf(token.taxReceiver());
        uint256 taxAmount = (amount * token.buySellTax()) / (100 * token.TAX_DIVISOR());

        vm.startPrank(user1);
        token.transfer(dexAddress, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(token.taxReceiver()), taxReceiverInitialBalance + taxAmount);

        // buy case

        amount = amount - taxAmount;
        taxReceiverInitialBalance = token.balanceOf(token.taxReceiver());
        taxAmount = (amount * token.buySellTax()) / (100 * token.TAX_DIVISOR());

        vm.startPrank(dexAddress);
        token.transfer(user1, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(dexAddress), 0);
        assertEq(token.balanceOf(token.taxReceiver()), taxReceiverInitialBalance + taxAmount);
    }

}
