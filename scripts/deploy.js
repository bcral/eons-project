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

let eonsProxyAddress = '0x0D7490af9668df0abb8b68476460e37b5E46C3Fa';
let eonsLpProxyAddress = '0x64c28e057B776Fb253F8ef1716403FF1CECE6759';
let eonsETHProxyAddress = '0x08ccE465DF5e4E4ce04554d786e492b3A84baA5c';
let eonsAaveVaultProxyAddress = '0xb90f37B4dC1653BF272571F92C45294244BF56C6';
let eonsUniVaultProxyAddress = '';
let eonsAaveRouterProxyAddress = '0x7DCA10F4d2Bc0550E33dB3C469e34620e5Cf8Cd1';
let eonsUniRouterProxyAddress = '';
let feeApprover = '0x5b495DaC603817B9AA54874DBb66e117cFa7e525';

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
  if (eonsProxyAddress) {
    // upgrade implementation
    await upgrade('Eons', eonsProxyAddress);
  } else {
    // deploy
    await deploy('Eons', 'initialize');
  }
};

const deployEonsLPToken = async () => {
  if (eonsLpProxyAddress) {
    // upgrade implementation
    await upgrade('EonsLP', eonsLpProxyAddress);
  } else {
    // deploy
    await deploy('EonsLP', 'initialize');
  }
};

const deployEonsETHToken = async () => {
  if (eonsETHProxyAddress) {
    await upgrade('EonsETH', eonsETHProxyAddress);
  } else {
    await deploy('EonsETH', 'initialize');
  }
};

const deployEonsAaveVault = async () => {
  if (eonsAaveVaultProxyAddress) {
    await upgrade('EonsAaveVault', eonsAaveVaultProxyAddress);
  } else {
    await deploy('EonsAaveVault', 'initialize', [eonsProxyAddress]);
  }
};

const deployEonsUniVault = async () => {
  if (eonsUniVaultProxyAddress) {
    await upgrade('EonsUniswapVault', eonsUniVaultProxyAddress);
  } else {
    await deploy('EonsUniswapVault', 'initialize', [eonsLpProxyAddress, eonsProxyAddress, devAddr, devAddr]);
  }
};

const deployEonsAaveRouter = async () => {
  if (eonsAaveRouterProxyAddress) {
    await upgrade('EonsAaveRouter', eonsAaveRouterProxyAddress);
  } else {
    await deploy('EonsAaveRouter', 'initialize', [aaveLendingPoolProviderAddress, eonsAaveVaultProxyAddress]);
  }
};

const deployFeeApprover = async () => {
  const FeeApprover = await hre.ethers.getContractFactory('FeeApprover');
  feeApprover = await FeeApprover.deploy();
  await feeApprover.deployed();
  await feeApprover.initialize(eonsProxyAddress, wethAddress, uniswapV2FactoryAddress);
  console.log('feeApprover deployed to:', feeApprover.address);
};

const deployEonsUniRouter = async () => {
  if (eonsUniRouterProxyAddress) {
    await upgrade('EonsUniswapRouter', eonsUniRouterProxyAddress);
  } else {
    await deploy('EonsUniswapRouter', 'initialize', [eonsProxyAddress, wethAddress, uniswapV2RouterAddress, feeApprover, eonsUniVaultProxyAddress]);
  }
};

const main = async () => {
  // await deployEonsToken();
  // await deployEonsLPToken();
  // await deployEonsETHToken();
  // await deployFeeApprover();
  // await deployEonsAaveVault();
  await deployEonsUniVault();
  // await deployEonsAaveRouter();
  // await deployEonsUniRouter();
};

main();
