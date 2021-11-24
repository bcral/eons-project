// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

import '../iEonsController.sol';
import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IAToken.sol';

  // Core Aave router functions:
  // Deposit:
  //  -approve erc20 transfer to Aave
  //  -deposit native asset to Aave
  //  -return aToken from Aave to vault
  // Withdraw:
  //  -transferFrom vault to this
  //  -approve aToken transfer to Aave
  //  -

contract EonsERC20AaveRouter is Ownable, iEonsController {
    using Address for address;
    using SafeERC20 for IERC20;

    event WithdrawError(uint256 indexed pid, string indexed erorr);

    // mapping connecting each native asset address to it's EONS vault address
    mapping(address => address) assetVault;

    uint16 public referralCode;

    modifier onlyVault(address _nativeAsset) {
        require(msg.sender == assetVault[_nativeAsset], "Only Vaults are authorized");
        _;
    }

    constructor() {
        referralCode = 0;
    }

    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }

    function setVault(address _nativeAddress, address _vaultAddress) external onlyOwner whenPaused {
        
        // Revert if this asset is already stored
        require(assetVault[_nativeAddress] == address(0), "That address is already saved.");
        // Save new vault address under the native asset address
        assetVault[_nativeAddress] = _vaultAddress;
    }

    function deposit(address _asset, uint256 _amount, address _user, address _lp) external onlyVault(_asset) {
    
        // Pull the asset + amount from user
        IERC20(_asset).safeTransferFrom(_user, address(this), _amount);
        // Approve the asset + amount for the lendingPool to pull
        IERC20(_asset).safeApprove(_lp, _amount);
        // Call deposit with the asset, amount, onBehalfOf(where to send aTokens), and referral code
        ILendingPool(_lp).deposit(_asset, _amount, assetVault[_asset], referralCode);
    }

    function withdraw(address _asset, uint256 _amount, address _aToken, address _recipient, address _lp) external onlyVault(_asset) {

        // Approve the most recent AAVE lending pool to transfer _amount
        IAToken(_aToken).approve(_lp, _amount);
        // Call withdraw on lending pool to return the native asset to _recipeint
        ILendingPool(_lp).withdraw(_asset, _amount, _recipient);
    }
}