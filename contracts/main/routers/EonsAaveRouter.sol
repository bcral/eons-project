// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
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

contract EonsAaveRouter is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    event WithdrawError(uint256 indexed pid, string indexed erorr);

    uint16 public referralCode;
    IEonsAaveVault public vault;
    IWETHGateway public WETHGateway;

    modifier onlyVault {
        require(msg.sender == address(vault), "Only Vault is authorized");
        _;
    }

    constructor(address _aaveVault, address _wETHGateway) {
        vault = IEonsAaveVault(_aaveVault);
        WETHGateway = IWETHGateway(_wETHGateway);
        referralCode = 0;
    }

    // Not required for AAVE - defaulted to 0 - but able to be reset in the future
    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }

    // Routes deposit to AAVE
    function depositMATIC(address _lp) external payable onlyVault {

        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.depositETH{value: msg.value}(_lp, address(vault), referralCode);
    }

    // Routes withdrawal transactions to AAVE
    function withdrawMATIC(uint256 _amount, address _user, address _lp, address _aToken) external onlyVault {
        
        // Approve WETHGateway to transfer aTokens from here
        IAToken(_aToken).approve(address(WETHGateway), _amount);
        // Send MATIC to WETHGateway for wrapping and deposit
        WETHGateway.withdrawETH(_lp, _amount, _user);
    }
}
