// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interfaces/IEonsAaveVault.sol';
import '../interfaces/IEonsUniVault.sol';
import '../interfaces/IEonsAaveRouter.sol';
import '../interfaces/IEonsUniRouter.sol';
import '../interfaces/IEons.sol';
import '../interfaces/IPriceOracle.sol';

contract Controller is OwnableUpgradeable {

  IEonsAaveVault public aaveVault;
  IEonsAaveRouter public aaveRouter;
  IEonsUniVault public uniVault;
  IEonsUniRouter public uniRouter;
  IEons public eons;
  IPriceOracle public priceOracle;
  uint256 public emissionRate;
  uint256 public emissionDistributionRateOfPools; // 70% of emissions
  uint256 public emissionDistributionRateOfLP; // 15% of emissions
  uint256 public emissionDistributionRateOfTreasury; // 15% of emissions
  uint public blockCreationTime;  // in seconds
  uint256 public lastEmissionCalcBlockNumber;
  address public treasury;

  function initialize(address _aaveVault, address _uniVault, address _aaveRouter, address _uniRouter, address _treasury, address _eons, address _priceOracle) external {
    __Ownable_init();
    eons = IEons(_eons);
    aaveVault = IEonsAaveVault(_aaveVault);
    aaveRouter = IEonsAaveRouter(_aaveRouter);
    uniVault = IEonsUniVault(_uniVault);
    uniRouter = IEonsUniRouter(_uniRouter);
    emissionRate = 35;
    emissionDistributionRateOfPools = 700;
    emissionDistributionRateOfLP = 150;
    emissionDistributionRateOfTreasury = 150;
    treasury = _treasury;
    blockCreationTime = 13;
    lastEmissionCalcBlockNumber = block.timestamp;
    priceOracle = IPriceOracle(_priceOracle);
  }

  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    return _to-_from;
  }

  function getPriceOf(uint _pid) external view returns (uint256) {
    require(address(priceOracle) != address(0));
    ( , address reserve, ) = aaveRouter.getAsset(_pid);
    return priceOracle.getAssetPrice(reserve);
  }

  function setBlockCreationTime(uint256 _blockCreationTime) external onlyOwner {
    blockCreationTime = _blockCreationTime;
  }

  function setPriceOracle(address _priceOracle) external onlyOwner {
    priceOracle = IPriceOracle(_priceOracle);
  }

  function updateTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setEonsToken(address _eons) external onlyOwner {
    eons = IEons(_eons);
  }

  function setEmissionRate(uint256 _emissionRate) external onlyOwner {
    emissionRate = _emissionRate;
  }

  function setEmissionDistributionRate(uint256 _poolDistributionRate, uint256 _lpDistributionRate, uint256 _treasuryDistributionRate) external onlyOwner {
    require(_poolDistributionRate+_lpDistributionRate+_treasuryDistributionRate == 1000, 'Error: invalid distribution rates');
    
    emissionDistributionRateOfPools = _poolDistributionRate;
    emissionDistributionRateOfLP = _lpDistributionRate;
    emissionDistributionRateOfTreasury = _treasuryDistributionRate;
  }

  function massUpdateEmissions() external {
    if (lastEmissionCalcBlockNumber < block.number) {
      uint256 multiplier = getMultiplier(lastEmissionCalcBlockNumber, block.number);
      uint256 totalEonsSupply = eons.totalSupply();
      uint256 emissions = (((totalEonsSupply*emissionRate)*(blockCreationTime)*(multiplier)/1000)/365)/86400;
      uint256 emissionsForPool = emissions*emissionDistributionRateOfPools/1000;
      uint256 emissionForLP = emissions*emissionDistributionRateOfLP/1000;
      uint256 emissionsForTreasury = emissions*emissionDistributionRateOfTreasury/1000;
      eons.mint(address(aaveVault), emissionsForPool);
      eons.mint(address(uniVault), emissionForLP);
      eons.mint(treasury, emissionsForTreasury);
      lastEmissionCalcBlockNumber = block.number;
      aaveVault.updateEmissionDistribution();
      uniVault.updateEmissionDistribution();
    }
  }
}
