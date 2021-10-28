// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ICoin.sol";


contract StableCoinToken is ERC20, ICoin, Ownable {
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory _name, string memory _symbol) 
        ERC20(_name, _symbol) {
    }

    /**
    @notice Mints a specified amount of tokens to an account
    @param account  the account to receive the new tokens
    @param amount  the amount to be minted
     */
    function mint(address account, uint256 amount) external override onlyOwner returns(bool) {
        super._mint(account, amount);
        return true;
    }

    /**
    @notice Burns a specified amount of tokens from an account
    @param account  the account to burn the tokens from
    @param amount  the amount to be burned
     */
    function burn(address account, uint256 amount) external override onlyOwner returns(bool) {
        super._burn(account, amount);
        return true;
    }
}