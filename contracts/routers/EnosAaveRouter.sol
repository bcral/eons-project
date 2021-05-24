// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import 'hardhat/console.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/ILendingPool.sol';
import '../interfaces/ILendingPoolAddressesProvider.sol';
import '../interfaces/IEonsAaveVault.sol';

contract EonsAaveRouter is OwnableUpgradeable {
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct AssetInfo {
    address aToken;
    address reserve;
    uint income;
  }

  ILendingPoolAddressesProvider private _lendingPoolAddressesProvider;
  IEonsAaveVault private _eonsAaveVault;
  mapping(uint => AssetInfo) private _assetInfo; // pid => aToken reserve address
  uint16 public _referralCode; 

  function initialize(address lendingPoolProvider, address eonsAaveVault) public initializer {
    _lendingPoolAddressesProvider = ILendingPoolAddressesProvider(lendingPoolProvider);
    _eonsAaveVault = IEonsAaveVault(eonsAaveVault);
    _eonsAaveVault.setRouterAddress(address(this));
    _referralCode = 0;
  }

  function addAaveToken(address reserve, address aToken, uint pid) public onlyOwner {
    _assetInfo[pid] = AssetInfo({reserve: reserve, aToken: aToken, income: 0});
  }

  function deposit(uint amount, uint pid) external {
    AssetInfo memory asset = _assetInfo[pid];
    require(asset.reserve != address(0), 'reserve address of this pool not be given yet');

    IERC20Upgradeable(asset.reserve).transferFrom(msg.sender, address(this), amount);
    ILendingPool lendingPool = ILendingPool(_lendingPoolAddressesProvider.getLendingPool());
    IERC20Upgradeable(asset.reserve).approve(address(lendingPool), amount);
    lendingPool.deposit(asset.reserve, amount, address(this), _referralCode);
    _eonsAaveVault.depositFor(msg.sender, amount, pid);
  }

  function depositETH() external payable {
    AssetInfo memory asset = _assetInfo[1]; // for WETH. pid 1 represents ETH.
    require(asset.reserve != address(0), 'reserve address of this pool has not been given yet');
    IWETH(asset.reserve).deposit{value: msg.value}();
    IWETH(asset.reserve).approve(address(_lendingPoolAddressesProvider), msg.value);
    ILendingPool lendingPool = ILendingPool(_lendingPoolAddressesProvider.getLendingPool());
    IERC20Upgradeable(asset.reserve).safeApprove(address(lendingPool), msg.value);

    lendingPool.deposit(asset.reserve, msg.value, address(this), _referralCode);
    _eonsAaveVault.depositFor(msg.sender, msg.value, 1);
  }

  function withdraw(uint pid, uint amount) external {
    AssetInfo memory asset = _assetInfo[pid]; // for WETH. pid 1 represents ETH.
    ILendingPool lendingPool = ILendingPool(_lendingPoolAddressesProvider.getLendingPool());
    lendingPool.withdraw(asset.reserve, amount, msg.sender);
  }
}
