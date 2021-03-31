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

const eonsProxyAddress = '';
const eonsLpProxyAddress = '';

const deploy = async (tokenName, initializerName) => {
  try {
    const SmartContract = await hre.ethers.getContractFactory(tokenName);
    const smartContract = await hre.upgrades.deployProxy(SmartContract, {initializer: initializerName});
    await smartContract.deployed();
    console.log(`[deploy] deployed ${tokenName} to => `, smartContract.address);
  } catch (error) {
    console.log('[deploy] error => ', error);
  }
};

const upgrade = async (tokenName, proxyAddress) => {
  try {
    const SmartContract = await hre.ethers.getContractFactory(tokenName);
    console.log('[upgrade] preparing upgrade...');
    const address = await hre.upgrades.prepareUpgrade(proxyAddress, SmartContract);
    console.log(`[upgrade] upgraded ${tokenName} at => `, address);
  } catch (error) {
    console.log('[upgrade] error => ', error);
  }
}

const deployEonsToken = () => {
  if (eonsProxyAddress) {
    // upgrade implementation
    upgrade('Eons', eonsProxyAddress);
  } else {
    // deploy
    deploy('Eons', 'initialize');
  }
};

const deployEonsLPToken = () => {
  if (eonsLpProxyAddress) {
    // upgrade implementation
    upgrade('EonsLP', eonsLpProxyAddress);
  } else {
    // deploy
    deploy('EonsLP', 'initialize');
  }
};

deployEonsToken();
// deployEonsLPToken();

// async function main() {
//   // Hardhat always runs the compile task when running scripts with its command
//   // line interface.
//   //
//   // If this script is run directly using `node` you may want to call compile 
//   // manually to make sure everything is compiled
//   // await hre.run('compile');

//   // deploys EONS
//   const Eons = await hre.ethers.getContractFactory('Eons');
//   const eons = await hre.upgrades.deployProxy(Eons, {initializer: 'initialize'});
//   await eons.deployed();
//   console.log('aj : ***** deployed Eons => ', eons);

//   // const eonsProxy = await Eons.attach(eons.address);
//   // console.log('aj : name => ', await eonsProxy.name())
//   const eonsTokenAddress = eons.address;

//   // deploys EonsLP
//   const EonsLP = await hre.ethers.getContractFactory('EonsLP');
//   const eonsLP = await EonsLP.deploy();

//   await eonsLP.deployed();

//   console.log('EonsLP deployed to:', eonsLP.address);

//   // deploys EonsVault
//   const EonsVault = await hre.ethers.getContractFactory('EonsVault');
//   const eonsVault = await EonsVault.deploy(eonsLP.address, eonsTokenAddress, process.env.DEV_ADDRESS, process.env.DEV_ADDRESS);

//   await eonsVault.deployed();
//   console.log('eonsVault deployed to:', eonsVault.address);

//   // deploys FeeApprover
//   const FeeApprover = await hre.ethers.getContractFactory('FeeApprover');
//   const feeApprover = await FeeApprover.deploy();

//   await feeApprover.deployed();
//   console.log('feeApprover deployed to:', feeApprover.address);

//   feeApprover.initialize(eonsTokenAddress, wethAddress, process.env.UNISWAP_FACTORY_ADDRESS);
//   console.log('feeApprover initialized');

//   // deploys EonsUniswapRouter
//   const EonsUniswapRouter = await hre.ethers.getContractFactory('EonsUniswapRouter');
//   const eonsUniswapRouter = await EonsUniswapRouter.deploy();

//   await eonsUniswapRouter.deployed();
//   console.log('eonsUniswapRouter deployed to:', eonsUniswapRouter.address);

//   // initializes EonsUniswapRouter
//   eonsUniswapRouter.initialize(eonsTokenAddress, wethAddress, UNISWAP_FACTORY_ADDRESS, feeApprover.address);
//   console.log('eonsUniswapRouter initialized');
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main()
//   .then(() => process.exit(0))
//   .catch(error => {
//     console.error(error);
//     process.exit(1);
//   });
