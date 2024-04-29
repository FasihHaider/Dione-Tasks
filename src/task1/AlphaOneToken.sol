// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlphaOneToken is ERC20, Ownable {
    
    string constant NAME = "Alpha One Token";
    string constant SYMBOL = "AOT";
    uint8 constant DECIMALS = 18;

    uint256 constant TOTAL_SUPPLY = 1_000_000;

    address public taxReceiver;
    
    uint256 public transferTax;
    uint256 public buySellTax;

    uint256 public constant TAX_DIVISOR = 100; // to support tax percentage upto two decimal places i.e., 0.01% can be minimum
    
    mapping(address => bool) public dexWhitelist;

    constructor(address initialOwner) ERC20(NAME, SYMBOL) Ownable(initialOwner) {
        require(initialOwner != address(0), "address should be valid");
        _mint(initialOwner, TOTAL_SUPPLY * 10 ** decimals());

        taxReceiver = initialOwner;
        transferTax = 5 * TAX_DIVISOR; // 5%
        buySellTax = 5 * TAX_DIVISOR; // 5% 
    }

    // Overriding if we need to change the decimals from 18
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function setTaxReceiver(address _taxReceiver) external onlyOwner {
        taxReceiver = _taxReceiver;
    }

    function setTransferTax(uint256 _transferTax) external onlyOwner {
        require(_transferTax <= 100 * TAX_DIVISOR, "invalid tax percentage");
        transferTax = _transferTax;
    }

    function setBuySellTax(uint256 _buySellTax) external onlyOwner {
        require(_buySellTax <= 100 * TAX_DIVISOR, "invalid tax percentage");
        buySellTax = _buySellTax;
    }

    function setWhitelist(address _dexAddress, bool _status) external onlyOwner {
        dexWhitelist[_dexAddress] = _status;
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        uint256 taxAmount;
        if (dexWhitelist[sender] || dexWhitelist[recipient]) {
            // Buy or sell detected
            taxAmount = (amount * buySellTax) / (100 * TAX_DIVISOR);
        } else {
            // Regular transfer
            taxAmount = (amount * transferTax) / (100 * TAX_DIVISOR);
        }
        super._update(sender, taxReceiver, taxAmount);
        super._update(sender, recipient, amount - taxAmount);
    }
}
