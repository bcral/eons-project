// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/ILendingPool.sol';

contract EonsAaveRouter is Ownable {
  using Address for address;
  using SafeMath for uint;

  struct AssetInfo {
    address aToken;
    address reserve;
    uint income;
  }

  ILendingPool private _lendingPool;
  IEonsAaveVault private _eonsAaveVault;
  mapping(uint => AssetInfo) private _assetInfo; // pid => aToken reserve address
  uint16 public _referralCode = 0; 

  constructor (address lendingPool, address eonsAaveVault) {
    _lendingPool = ILendingPool(lendingPool);
    _lendingPool.setRouterAddress(address(this));
    _eonsAaveVault = IEonsAaveVault(eonsAaveVault);
  }

  function addAaveToken(address reserve, address aToken, uint pid) public onlyOwner {
    _assetInfo[pid] = AssetInfo({reserve: reserve, aToken: aToken, income: 0});
  }

  function deposit(uint amount, uint pid) external payable {
    AssetInfo memory asset = _assetInfo[pid];
    require(asset.reserve, 'reserve address of this pool not be given yet');

    IERC20(asset.reserve).transfer(msg.sender, address(this), amount);
    IERC20(asset.reserve).approve(_lendingPool, amount);
    _deposit(asset.reserve, amount);
    _eonsAaveVault.depositFor(msg.sender, amount, pid);
  }

  function depositETH() external payable {
    AssetInfo memory asset = _assetInfo[1]; // for WETH. pid 1 represents ETH.
    require(asset.reserve, 'reserve address of this pool not be given yet');
    IWETH(asset.reserve).deposit{value: msg.value}();
    IWETH(asset.reserve).approve(address(_lendingPool), msg.value);
    _deposit(asset.reserve, amount);
    _eonsAaveVault.depositFor(msg.sender, amount, pid);
  }

  function _deposit(address reserve, uint amount) private {
    _lendingPool.deposit.value(msg.value)(reserve, amount, address(this), _referralCode);
  }
}
