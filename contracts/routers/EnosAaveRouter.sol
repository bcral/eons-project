// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import 'hardhat/console.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/ILendingPool.sol';
import '../interfaces/ILendingPoolAddressesProvider.sol';
import '../interfaces/IAToken.sol';
import '../interfaces/IWETHGateway.sol';

contract EonsAaveRouter is OwnableUpgradeable {
  using AddressUpgradeable for address;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct AssetInfo {
    address aToken;
    address reserve;
    uint income;
  }

  event WithdrawError(uint256 indexed pid, string indexed erorr);

  ILendingPoolAddressesProvider public lendingPoolAddressesProvider;
  mapping(uint => AssetInfo) public assetInfo; // pid => aToken reserve address
  IWETHGateway wethGateway;
  uint16 public referralCode;

  function initialize(address _lendingPoolProvider, address _wethGateway) external initializer {
    lendingPoolAddressesProvider = ILendingPoolAddressesProvider(_lendingPoolProvider);
    referralCode = 0;
    wethGateway = IWETHGateway(_wethGateway);
    __Ownable_init();
  }

  function getAsset(uint256 _pid) external view returns (address aToken, address reserve, uint256 income) {
    aToken = assetInfo[_pid].aToken;
    reserve = assetInfo[_pid].reserve;
    income = assetInfo[_pid].income;
  }

  function pendingRewardOf(uint256 _pid) external view returns (uint256) {
    AssetInfo memory asset = assetInfo[_pid];
    uint256 pending = IAToken(asset.aToken).scaledBalanceOf(address(this));
    return pending;
  }

  function totalStakedOf(uint _pid) external view returns (uint256) {
    AssetInfo storage asset = assetInfo[_pid];
    uint totalDepositValue = IAToken(asset.aToken).balanceOf(address(this));
    return totalDepositValue;
  }

  function addAaveToken(address _reserve, address _aToken, uint _pid) external onlyOwner {
    assetInfo[_pid] = AssetInfo({reserve: _reserve, aToken: _aToken, income: 0});
  }

  function updateAaveToken(uint256 _pid, address _reserve, address _aToken) external onlyOwner {
    AssetInfo storage asset = assetInfo[_pid];
    asset.reserve = _reserve;
    asset.aToken = _aToken;
  }

  function deposit(uint _amount, uint _pid, address _user) external {
    AssetInfo memory asset = assetInfo[_pid];
    require(asset.reserve != address(0), 'reserve address of this pool not be given yet');

    IERC20Upgradeable(asset.reserve).safeTransferFrom(_user, address(this), _amount);
    ILendingPool lendingPool = ILendingPool(lendingPoolAddressesProvider.getLendingPool());
    IERC20Upgradeable(asset.reserve).safeApprove(address(lendingPool), _amount);

    lendingPool.deposit(asset.reserve, _amount, address(this), referralCode);
  }

  function withdraw(uint _pid, uint _amount, address _recipient) external {
    AssetInfo memory asset = assetInfo[_pid];
    ILendingPool lendingPool = ILendingPool(lendingPoolAddressesProvider.getLendingPool());
    try IAToken(asset.aToken).approve(address(wethGateway), _amount) returns (bool) {

    } catch Error(string memory reason) {
      emit WithdrawError(_pid, reason);
    }
    if (_pid == 1) {  // if withdrawing eth. hard coded
      wethGateway.withdrawETH(address(lendingPool), _amount, _recipient);
    } else {
      try lendingPool.withdraw(asset.reserve, _amount, _recipient) returns (uint256 returnedVaule) {

      } catch Error(string memory reason) {
        emit WithdrawError(_pid, reason);
      }
    }
  }
}
