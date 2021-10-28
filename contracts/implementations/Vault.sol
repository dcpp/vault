// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IVault.sol";
import "../implementations/Coin.sol";


contract Vault is Context, IVault {
    
    uint256 constant rate_mul = 100;
    uint256 constant rate_div = 2;

    mapping(address=>Vault) private vaults;
    ICoin public immutable coin;

    /**
     * @dev Creates stable coin with the values for {name} and {symbol}.
     *
     */
    constructor(string memory _name, string memory _symbol) {
        coin = new StableCoinToken(_name, _symbol);
    }

    /**
    @notice Allows a user to deposit ETH collateral in exchange for some amount of stablecoin
    @param amountToDeposit  The amount of ether the user sent in the transaction
     */
    function deposit(uint256 amountToDeposit) external payable override {
        require(amountToDeposit > 0 && amountToDeposit == msg.value, "VAULT: Requested withdraw exeeds coin amount");
        
        uint256 amountMinted = _estimateAmount(amountToDeposit, true);
        require(amountMinted > 0, "VAULT: Too small amount");

        Vault storage vault = vaults[_msgSender()];
        vault.collateralAmount += amountToDeposit;
        vault.debtAmount += amountMinted;

        coin.mint(_msgSender(), amountMinted);

        emit Deposit(amountToDeposit, amountMinted);
    }
    
    /**
    @notice Allows a user to withdraw up to 100% of the collateral they have on deposit
    @dev This cannot allow a user to withdraw more than they put in
    @param repaymentAmount  the amount of stablecoin that a user is repaying to redeem their collateral for.
     */
    function withdraw(uint256 repaymentAmount) external override {
        Vault storage vault = vaults[_msgSender()];
        require(vault.debtAmount >= repaymentAmount, "VAULT: Requested withdraw exeeds coin amount");

        uint256 collateralWithdrawn = _estimateAmount(repaymentAmount, false);
        require(vault.collateralAmount >= collateralWithdrawn, "VAULT: Requested withdraw exeeds collateral");
        
        vault.collateralAmount -= collateralWithdrawn;
        vault.debtAmount -= repaymentAmount;

        coin.burn(_msgSender(), repaymentAmount);

        (bool success, ) = _msgSender().call{value: collateralWithdrawn}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');        

        emit Withdraw(collateralWithdrawn, repaymentAmount);
    }
    
    /**
    @notice Returns the details of a vault
    @param userAddress  the address of the vault owner
    @return vault  the vault details
     */
    function getVault(address userAddress) external view override returns(Vault memory vault) {
        return vaults[userAddress];
    }
    
    /**
    @notice Returns an estimate of how much collateral could be withdrawn for a given amount of stablecoin
    @param repaymentAmount  the amount of stable coin that would be repaid
    @return collateralAmount the estimated amount of a vault's collateral that would be returned 
     */
    function estimateCollateralAmount(uint256 repaymentAmount) external pure override returns(uint256 collateralAmount) {
        return _estimateAmount(repaymentAmount, false);
    }
    
    /**
    @notice Returns an estimate on how much stable coin could be minted at the current rate
    @param depositAmount the amount of ETH that would be deposited
    @return tokenAmount  the estimated amount of stablecoin that would be minted
     */
    function estimateTokenAmount(uint256 depositAmount) external pure override returns(uint256 tokenAmount) {
        return _estimateAmount(depositAmount, true);
    }

    function _estimateAmount(uint256 amount, bool stableCoinToETH) pure internal returns(uint256) {

        return stableCoinToETH ? (amount * rate_mul / rate_div) 
            : (amount * rate_div / rate_mul);
    }
}
