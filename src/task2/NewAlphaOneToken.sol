// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NewAlphaOneToken is ERC20, Ownable {
    
    string constant NAME = "New Alpha One Token";
    string constant SYMBOL = "NAOT";
    uint8 constant DECIMALS = 18;
    
    uint256 constant additionalSupply = 1_000_000;

    address public oldTokenReceiver;
    IERC20 public oldToken;

    constructor(address _oldToken, address initialOwner) ERC20(NAME, SYMBOL) Ownable(initialOwner) {
        require(_oldToken != address(0), "old token address cannot be zero");
        require(initialOwner != address(0), "owner address cannot be zero");
        
        _mint(initialOwner, additionalSupply * 10 ** decimals()); // incase we need to mint additional tokens other than migration
        oldToken = IERC20(_oldToken);
    }

    // generic for all tokens in which we consider the initial sent amount
    function migrateWithoutTax(uint256 amount) public {
        if (oldTokenReceiver != address(0)) {
            require(oldToken.transferFrom(msg.sender, oldTokenReceiver, amount), "transfer failed");
        }
        else {
            require(oldToken.transferFrom(msg.sender, address(this), amount), "transfer failed");
        }
        _mint(msg.sender, amount);
    }

    // specific for taxed tokens in which we consider the final received amount
    function migrateWithTax(uint256 amount) public {
        uint256 mintAmount;
        if (oldTokenReceiver != address(0)) {
            uint256 previousBalance = IERC20(oldToken).balanceOf(oldTokenReceiver);
            require(oldToken.transferFrom(msg.sender, oldTokenReceiver, amount), "transfer failed");
            mintAmount = IERC20(oldToken).balanceOf(oldTokenReceiver) - previousBalance;
        }
        else {
            uint256 previousBalance = IERC20(oldToken).balanceOf(address(this));
            require(oldToken.transferFrom(msg.sender, address(this), amount), "transfer failed");
            mintAmount = IERC20(oldToken).balanceOf(address(this)) - previousBalance;
        }
        _mint(msg.sender, mintAmount);
    }

    /*
    Rest of the functions can be added as per requirements
    */

    // Optional: function to update the old token address if necessary
    function setOldToken(address _oldToken) public onlyOwner {
        require(_oldToken != address(0), "invalid address");
        oldToken = IERC20(_oldToken);
    }

    // Optional: function to update the old token receiver address if necessary
    function setOldTokenReceiver(address _oldTokenReceiver) public onlyOwner {
        oldTokenReceiver = _oldTokenReceiver;
    }
}
