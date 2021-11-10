// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import 'hardhat/console.sol';

import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IEonsAaveVault.sol';
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

contract EonsAaveRouter is Ownable, Pausable {
    using Address for address;
    using SafeERC20 for IERC20;

    event WithdrawError(uint256 indexed pid, string indexed erorr);

    uint16 public referralCode;
    IEonsAaveVault public vault;
    IWETHGateway public WETHGateway;

    modifier onlyEonsAaveVault {
        require(msg.sender == address(vault), "Only EonsAaveVault is authorized");
        _;
    }

    constructor(address _aaveVault, address _wETHGateway) {
        vault = IEonsAaveVault(_aaveVault);
        WETHGateway = IWETHGateway(_wETHGateway);
        referralCode = 0;
    }

    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }

    function setVault(address _vault) external onlyOwner whenPaused {
        vault = IEonsAaveVault(_vault);
    }

    function deposit(address _asset, uint256 _amount, address _user, address _lp) external onlyEonsAaveVault {
    
        // Pull the asset + amount from user
        IERC20(_asset).safeTransferFrom(_user, address(this), _amount);
        // Approve the asset + amount for the lendingPool to pull
        IERC20(_asset).safeApprove(_lp, _amount);
        // Call deposit with the asset, amount, onBehalfOf(where to send aTokens), and referral code
        ILendingPool(_lp).deposit(_asset, _amount, address(vault), referralCode);
    }

    function withdraw(address _asset, uint256 _amount, address _aToken, address _recipient, address _lp) external onlyEonsAaveVault {

        // Approve the most recent AAVE lending pool to transfer _amount
        IAToken(_aToken).approve(_lp, _amount);
        // Call withdraw on lending pool to return the native asset to _recipeint
        ILendingPool(_lp).withdraw(_asset, _amount, _recipient);
    }

    function depositMATIC(address _lp) external payable onlyEonsAaveVault {

        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.depositETH{value: msg.value}(_lp, address(vault), referralCode);
    }

    function withdrawMATIC(uint256 _amount, address _user, address _lp, address _aToken) external onlyEonsAaveVault {
        
        // Approve WETHGateway to transfer aTokens from here
        IAToken(_aToken).approve(address(WETHGateway), _amount);
        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.withdrawETH(_lp, _amount, _user);
    }
}
