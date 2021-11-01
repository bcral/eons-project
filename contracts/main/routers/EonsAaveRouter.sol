// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import 'hardhat/console.sol';

import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IEonsAaveVault.sol';
import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/interfaces/IWMATIC.sol';
import '../../peripheries/interfaces/IWETHGateway.sol';

  // Core Aave router functions:
  // Deposit:
  //  -approve erc20 transfer to Aave
  //  -deposit native asset to Aave
  //  -return aToken from Aave to vault
  // Withdraw:
  //  -transferFrom vault to this
  //  -approve aToken transfer to Aave
  //  -

contract EonsAaveRouter is OwnableUpgradeable, PausableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event WithdrawError(uint256 indexed pid, string indexed erorr);

    uint16 public referralCode;
    IEonsAaveVault public aaveVault;
    IiEonsController public controller;
    IWETHGateway public WETHGateway;
    IWMATIC public WMATIC;

    modifier onlyEonsAaveVault {
        require(msg.sender == address(aaveVault), "Only EonsAaveVault is authorized");
        _;
    }

    function initialize(address _aaveVault, address _wmatic, address _wETHGateway) external initializer {
        aaveVault = IEonsAaveVault(_aaveVault);
        WMATIC = IWMATIC(_wmatic);
        WETHGateway = IWETHGateway(_wETHGateway);
        referralCode = 0;
        __Ownable_init();
    }

    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }

    function setControllerAddress(address _controller) external onlyOwner {
        controller = IiEonsController(_controller);
    }

    function setVault(address _vault) external onlyOwner {
        aaveVault = IEonsAaveVault(_vault);
    }

    function deposit(address _asset, uint256 _amount, address _user, address _lp) external onlyEonsAaveVault {
    
        // Pull the asset + amount from user
        IERC20Upgradeable(_asset).safeTransferFrom(_user, address(this), _amount);
        // Approve the asset + amount for the lendingPool to pull
        IERC20Upgradeable(_asset).safeApprove(_lp, _amount);
        // Call deposit with the asset, amount, onBehalfOf(where to send aTokens), and referral code
        ILendingPool(_lp).deposit(_asset, _amount, address(aaveVault), referralCode);
    }

    function withdraw(address _asset, uint256 _amount, address _aToken, address _recipient, address _lp) external onlyEonsAaveVault {

        // Approve the most recent AAVE lending pool to transfer _amount
        IAToken(_aToken).approve(_lp, _amount);
        // Call withdraw on lending pool to return the native asset to _recipeint
        ILendingPool(_lp).withdraw(_asset, _amount, _recipient);
    }

    function depositMATIC(address _lp) external payable onlyEonsAaveVault {

        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.depositETH{value: msg.value}(_lp, address(aaveVault), referralCode);
    }

    function withdrawMATIC(uint256 _amount, address _user, address _lp) external onlyEonsAaveVault {
    
        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.withdrawETH(_lp, _amount, _user);
    }
}
