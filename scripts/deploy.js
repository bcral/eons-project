require('dotenv').config();
const hre = require('hardhat');

// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

let wethAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';

if (process.env.NETWORK == 'mainnet') {
  wethAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
} else if (process.env.NETWORK == 'kovan') {
  wethAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c';
} else if (process.env.NETWORK == 'rinkeby') {
  wethAddress = '0xc778417E063141139Fce010982780140Aa0cD5Ab';
}

const aaveLendingPoolProviderAddress = '0x88757f2f99175387ab4c6a4b3067c77a695b0349';  // should be updated with getting latest lending pool address from lending pool provider contract
const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const uniswapV2RouterAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const devAddr = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';
const treasury = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';

let eonsAddress = '0x18159d5e8Dd14557EDF952807591D51f9f9df1d9';
let eonsLpAddress = '0x86428D8E96271AFFbc2BB431E8a65Dbcb5AF6D63';
let eonsETHAddress = '0x43611b03E53e31e5D93E6047417ab81FD5Ad0326';
let eonsAaveVaultProxyAddress = '0xABDD2086B780DcF663325Da0653B5b50324B9231';
let eonsUniVaultProxyAddress = '0x9693794a3713e316d707b51241892b02ABc465e1';
let eonsAaveRouterProxyAddress = '0x1f4b9b21D1fCa896Ff2E82767b2def2327822207';
let eonsUniRouterProxyAddress = '0xbE91AEED023b4dcF98fB308bB0C5acD258781474';
let feeApproverAddress = '0x95C9D6cb238570d49464cf442bF489A9271b8c33';
let controllerProxyAddress = '0x99510B132a986A1978952Ebe8dA2cc1BD8032d43';
let wethGatewayAddress = '0x5c57Af46461b6c425fb43A354FeEF6d5680169d1';

const deploy = async (tokenName, initializerName, args = []) => {
  try {
    const SmartContract = await hre.ethers.getContractFactory(tokenName);
    const smartContract = await hre.upgrades.deployProxy(SmartContract, args, {initializer: initializerName});
    await smartContract.deployed();
    console.log(`[deploy] deployed ${tokenName} proxy to => `, smartContract.address);
    // console.log('Transferring ownership of ProxyAdmin...');
    // console.log('*****', await hre.upgrades.admin.transferProxyAdminOwnership('0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272'));
    // console.log('Transferred ownership of ProxyAdmin to:', '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272');
  } catch (error) {
    console.log('[deploy] error => ', error);
  }
};

const upgrade = async (tokenName, proxyAddress) => {
  try {
    const SmartContract = await hre.ethers.getContractFactory(tokenName);
    console.log('[upgrade] preparing upgrade...');
    const address = await hre.upgrades.upgradeProxy(proxyAddress, SmartContract);
    console.log(`[upgrade] upgraded ${tokenName}`);
  } catch (error) {
    console.log('[upgrade] error => ', error);
  }
}

const deployEonsToken = async () => {
  const Eons = await hre.ethers.getContractFactory('Eons');
  eons = await Eons.deploy();
  await eons.deployed();
  await eons.initialize();
  console.log('eons deployed to:', eons.address);
};

const deployEonsLPToken = async () => {
  const EonsLP = await hre.ethers.getContractFactory('EonsLP');
  eonsLP = await EonsLP.deploy();
  await eonsLP.deployed();
  await eonsLP.initialize();
  console.log('eonsLP deployed to:', eonsLP.address);
};

const deployEonsETHToken = async () => {
  const EonsETH = await hre.ethers.getContractFactory('EonsETH');
  eonsETH = await EonsETH.deploy();
  await eonsETH.deployed();
  await eonsETH.initialize();
  console.log('eonsETH deployed to:', eonsETH.address);
};

const deployEonsAaveVault = async () => {
  if (eonsAaveVaultProxyAddress) {
    await upgrade('EonsAaveVault', eonsAaveVaultProxyAddress);
  } else {
    if (eonsAaveRouterProxyAddress) {
      await deploy('EonsAaveVault', 'initialize', [eonsAddress, devAddr, eonsAaveRouterProxyAddress]);
    }
  }
};

const deployEonsUniVault = async () => {
  if (eonsUniVaultProxyAddress) {
    await upgrade('EonsUniswapVault', eonsUniVaultProxyAddress);
  } else {
    await deploy('EonsUniswapVault', 'initialize', [eonsLpAddress, eonsAddress, devAddr, devAddr]);
  }
};

const deployWETHGateway = async () => {
  const WETHGateway = await hre.ethers.getContractFactory('WETHGateway');
  wETHGateway = await WETHGateway.deploy(wethAddress);
  await wETHGateway.deployed();
  console.log('wETHGateway deployed to:', wETHGateway.address);
};

const deployEonsAaveRouter = async () => {
  if (eonsAaveRouterProxyAddress) {
    await upgrade('EonsAaveRouter', eonsAaveRouterProxyAddress);
  } else {
    if (wethGatewayAddress) {
      await deploy('EonsAaveRouter', 'initialize', [aaveLendingPoolProviderAddress, wethGatewayAddress]);
    }
  }
};

const deployFeeApprover = async () => {
  const FeeApprover = await hre.ethers.getContractFactory('FeeApprover');
  feeApprover = await FeeApprover.deploy();
  await feeApprover.deployed();
  await feeApprover.initialize(eonsAddress, wethAddress, uniswapV2FactoryAddress);
  console.log('feeApprover deployed to:', feeApprover.address);
};

const deployEonsUniRouter = async () => {
  if (eonsUniRouterProxyAddress) {
    await upgrade('EonsUniswapRouter', eonsUniRouterProxyAddress);
  } else {
    await deploy('EonsUniswapRouter', 'initialize', [eonsAddress, wethAddress, uniswapV2FactoryAddress, feeApproverAddress, eonsUniVaultProxyAddress]);
  }
};

const deployController = async () => {
  if (controllerProxyAddress) {
    await upgrade('Controller', eonsUniRouterProxyAddress);
  } else {
    if (!!eonsAddress && !!eonsAaveVaultProxyAddress && !!eonsUniVaultProxyAddress && !!eonsAaveRouterProxyAddress && !!eonsUniRouterProxyAddress) {
      await deploy('Controller', 'initialize', [
        eonsAaveVaultProxyAddress,
        eonsUniVaultProxyAddress,
        eonsAaveRouterProxyAddress,
        eonsUniRouterProxyAddress,
        treasury,
        eonsAddress
      ]);
    }
  }
};

const main = async () => {
  // await deployEonsToken();
  // await deployEonsLPToken();
  // await deployEonsETHToken();
  // await deployFeeApprover();
  // await deployEonsUniVault();
  // await deployWETHGateway();
  // await deployEonsUniRouter();
  // await deployEonsAaveRouter();
  await deployEonsAaveVault();
  // await deployController();
};

main();
