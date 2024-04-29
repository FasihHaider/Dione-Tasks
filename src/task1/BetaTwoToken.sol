// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BetaTwoToken is ERC20 {
    
    string constant _name = "Beta Two Token";
    string constant _symbol = "BTT";
    uint8 constant _decimals = 18;
    
    uint256 constant _totalSupply = 12_000_000;

    constructor(address initialOwner) ERC20(_name, _symbol) {
        require(initialOwner != address(0), "address should be valid");
        _mint(initialOwner, _totalSupply * 10 ** decimals());
    }

    // Overriding if we need to change the decimals from 18
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}