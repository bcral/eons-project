require('dotenv').config();
const hre = require('hardhat');

const zero = '0x0000000000000000000000000000000000000000';

// Declare all mainnet addresses here

const QSRouter = '0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff';

// aTokens
const aTokenMaticContract = '0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4';
const aTokenUSDCContract = '0x1a13F4Ca1d028320A707D99520AbFefca3998b7F';
const aTokenDAIContract = '0x27F8D03b3a2196956ED754baDc28D73be8830A6e';

const wmatic = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';
const wETHGateway = '0xbEadf48d62aCC944a06EEaE0A9054A90E5A7dc97';
const maticLendingPool = '0x8dff5e27ea6b7ac08ebfdf9eb090f32ee9a30fcf';
const bonusRewards = '0x357D51124f59836DeD84c8a1730D72B749d8BC23';
// USDC address on Polygon
const nativeAsset1 = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
// DAI address on Polygon
const nativeAsset2 = '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063';

// Declare all globals that will need access elseware:
let lendingPool = '0x8dff5e27ea6b7ac08ebfdf9eb090f32ee9a30fcf'; 
// David's MATIC address for simulating Dev withdrawals
// Actually just a dummy testnet address
let devVault = '0xF6c7D4b4821989Ecc5dE6Fb6Ff41D110463218C5';

let dsmathAddress;
let eaEonsAddress;
let eonsAddress;
let eonsControllerAddress;

// Declare all globals for testing
let vault;
let eaEons;
let router;

// Deploy contracts in this order:
// Libraries
// Contracts
// Tokens

// Library deployments:

async function DSMathDeploy () {
    // We get the contract to deploy
    const DSMath = await ethers.getContractFactory('DSMath');
    console.log('Deploying DSMath...');
    const dsmath = await DSMath.deploy();
    await dsmath.deployed();
    dsmathAddress = dsmath.address;
    console.log('DSMath deployed to:', dsmathAddress);
}

// Contract deployments:

// async function AaveVaultDeploy () {
//     // We get the contract to deploy
//     const Vault = await ethers.getContractFactory('EonsMATICAaveVault');
//     console.log('Deploying AAVE Vault...');
//     // (_wmatic, _bonusAddress, _devVault, _aTokenAddress)
//     vault = await Vault.deploy(wmatic, bonusRewards, devVault, aTokenMaticContract);
//     await vault.deployed();
//     console.log('Vault deployed to:', vault.address);
// }

async function AaveVaultDeploy () {
    // We get the contract to deploy
    const Vault = await ethers.getContractFactory('EonsERC20AaveVault');
    console.log('Deploying AAVE Vault...');
    // (_wmatic, _bonusAddress, _devVault, _aTokenAddress)
    vault = await Vault.deploy(wmatic, bonusRewards, devVault, aTokenDAIContract, nativeAsset2, lendingPool, QSRouter);
    await vault.deployed();
    console.log('Vault deployed to:', vault.address);
}

// router for ERC20 interactions
// NEEDS VAULT ADDRESS INTEGRATED TO USE
async function AaveRouterDeploy () {
    // We get the contract to deploy
    const Router = await ethers.getContractFactory('EonsERC20AaveRouter');
    console.log('Deploying AAVE Router...');
    router = await Router.deploy();
    await router.deployed();
    console.log('Router deployed to:', router.address);
}

async function EonsControllerDeploy () {
    // We get the contract to deploy
    const EonsController = await ethers.getContractFactory('iEonsController');
    console.log('Deploying Controller...');
    const eonsController = await EonsController.deploy();
    await eonsController.deployed();
    eonsControllerAddress = eonsController.address;
    console.log('Controller deployed to:', eonsControllerAddress);
}

// Token deployments:

async function eaEonsDeploy () {
    // We get the contract to deploy
    const EaEons = await ethers.getContractFactory('eaEons');
    console.log('Deploying eaEons...');
    eaEons = await EaEons.deploy(aTokenDAIContract, vault.address);
    await eaEons.deployed();
    eaEonsAddress = eaEons.address
    console.log('eaEons deployed to:', eaEonsAddress);
}

async function EonsDeploy () {
    // We get the contract to deploy
    const Eons = await ethers.getContractFactory('Eons');
    console.log('Deploying Eons...');
    const eons = await Eons.deploy();
    await eons.deployed();
    eonsAddress = eons.address
    console.log('Eons deployed to:', eonsAddress);
}

// deploy all contracts with this function
async function main () {

    await DSMathDeploy();
    await EonsControllerDeploy();
    // await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await eaEonsDeploy();
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupVault() {
    // await vault.pause();
    // await vault.setRouterAddress(router.address);
    // await vault.editAsset('0x8dff5e27ea6b7ac08ebfdf9eb090f32ee9a30fcf');
    // await vault.setETokenAddress(eaEonsAddress);
    // await vault.unPause();
    // await router.pause();
    // await router.setVault(nativeAsset2, vault.address);
    // await router.unPause();

    // const USDC = await ethers.getContractFactory('ERC20');
    // const usdc = await USDC.attach('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174');
    // await usdc.approve('router.address', 2000000);

    // FOR SPOOFING ACCOUNT ON FORKED MAINNET:

    // // Populate with account containing Polygon USDC
    // const accountToInpersonate = "0xC91687aBa56Ad9ace0867A56e1FA84eddDAdD591";

    // await hre.network.provider.request({
    //     method: "hardhat_impersonateAccount",
    //     params: [accountToInpersonate],
    // });

    // const me = await ethers.getSigner(accountToInpersonate);

    // const USDC = await ethers.getContractFactory('ERC20');
    // const usdc = await USDC.attach('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174');

    // await usdc.connect(me).approve(router.address, 2000000);
    // await vault.connect(me).deposit(2000000);
    console.log('Vault setup complete...');
}

// setup all contracts with this function
async function setup () {

    await setupVault();

    console.log('Setup complete...');
}
  
async function runEverything() {
    await main();
    await setup();
}

runEverything();

// To deploy contract:
// npx hardhat run scripts/deploy_matic-testnet.js --network Mumbai

// Then...(copy/paste into npx hardhat console --network localhost):

// const Vault = await ethers.getContractFactory('EonsERC20AaveVault');
// const vault = await Vault.attach('');

    // await vault.pause();
    // await vault.setRouterAddress(router.address);
    // await vault.editAsset('0x8dff5e27ea6b7ac08ebfdf9eb090f32ee9a30fcf');
    // await vault.setETokenAddress(eaEonsAddress);
    // await vault.unPause();

// const Router = await ethers.getContractFactory('EonsERC20AaveRouter');
// const router = await Router.attach('');

    // await router.pause();
    // await router.setVault('0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063', vault.address);
    // await router.unPause();

// const DAI = await ethers.getContractFactory('ERC20');
// const dai = await DAI.attach('0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063');

    // await dai.approve(router, '2000000000000000000');

// const eaEons = await ethers.getContractFactory('eaEons');
// const eaeons = await eaEons.attach('');


// (await eaeons.eTotalSupply()).toString();
// (await eaeons.totalSupply()).toString();
// (await eaeons.balanceOf('')).toString();
// (await eaeons.getA()).toString();
// (await eaeons.getCurrentIndex()).toString();
// (await eaeons.getNewIndex()).toString();
// (await vault.devA('0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4')).toString();

// Populate with account containing Polygon USDC
// const accountToInpersonate = "0xB0ED674f8A4fD73Fc15511ec64ce14c6ae084B64";

//  await hre.network.provider.request({
//     method: "hardhat_impersonateAccount",
//     params: [accountToInpersonate],
//   });

// const me = await ethers.getSigner(accountToInpersonate);

// Approve 2 USDC to the router
// await usdc.connect(me).approve(router.address, 2000000)

// Call deposit(2000000) from me
// await vault.connect(me).deposit(2000000);


// await vault.depositMATIC({value: '50000000000000000000'});
// await vault.withdrawMATIC('10000000000000000000');

// FOR VERIFICATION

// DSMath
// npx hardhat verify --contract contracts/peripheries/libraries/DSMath.sol:DSMath <address> --network Mumbai
// on Polygonscan:
// 

// Vault
// npx hardhat verify --contract contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault <address> --network Mumbai
// on Polygonscan:
// https://polygonscan.com/address/0x9D13DA4c2377EFa3F0Ccb82C24959B709B490409#code
// https://polygonscan.com/address/0x4602B4F1870e6aaefcEd9E71E754A88686e14928#code


// Router
// npx hardhat verify --contract contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter <address> --network Mumbai
// on Polygonscan:
// https://polygonscan.com/address/0xD502bC719a0DB6Ab57eeAf45Fe29B6e4dcabc8ac#code

// eaEons
// npx hardhat verify --contract contracts/main/tokens/eaEons.sol:eaEons <address> --network Mumbai
// on Polygonscan:
// https://polygonscan.com/address/0x74C053E17B26DeB725F30890C5922e4bb8fde5A2#code

// npx hardhat verify \
// --network Polygon \
// --constructor-args scripts/args/eaeons-args.js \
// --contract contracts/main/tokens/eaEons.sol:eaEons \
// 0x143404d0133f4bD40827c7edA37f184d286a3Def

// npx hardhat verify \
// --network Polygon \
// --constructor-args scripts/args/vault-args.js \
// --contract contracts/main/vaults/EonsERC20AaveVault.sol:EonsERC20AaveVault \
// 0x4602B4F1870e6aaefcEd9E71E754A88686e14928

// USDC eaEons address 0x9B05DA3EC5eF18D7932056324401Da8B3f0E0335
