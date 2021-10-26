// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../peripheries/interfaces/IEonsAaveVault.sol';
import '../peripheries/interfaces/IEonsUniVault.sol';
import '../peripheries/interfaces/IEonsAaveRouter.sol';
import '../peripheries/interfaces/IEonsUniRouter.sol';
import '../peripheries/interfaces/IEons.sol';
import '../peripheries/interfaces/IPriceOracle.sol';

contract Controller is OwnableUpgradeable {

  struct PoolInterestRate {
    uint256 pid;
    uint256 rate;
    bool increased;
  }

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
    lastEmissionCalcBlockNumber = block.number;
    priceOracle = IPriceOracle(_priceOracle);
  }

  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    return _to-_from;
  }

  function getPriceOf(uint _pid) public view returns (uint256) {
    require(address(priceOracle) != address(0));
    // causing error, so commenting out for now
    // ( , address reserve, ) = aaveRouter.getAsset(_pid);
    // return priceOracle.getAssetPrice(reserve);
  }

  function getAaveLiquidityRate(uint256 _pid) public view returns (uint256) {
    // causing error, so commenting out for now
    // uint256 liquidityRate = aaveRouter.liquidityRateOf(_pid);
    // return liquidityRate;
  }

  function getUniReserves() public view returns (uint256 reserve0, uint256 reserve1) {
    (reserve1, reserve0) = uniRouter.getPairReserves();
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


  // Returns user's discount status - true or false
  // Calls the appropriate sources and determines eligability at user deposit
  function getUsersDiscountStat(address _user) public view returns(bool) {
      // Do the thing here:
      // If discounted, return true
      if (true) {
          return true;
      } else {
          return false;
      }
  }
}
