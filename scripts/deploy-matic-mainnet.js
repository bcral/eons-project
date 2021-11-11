require('dotenv').config();
const hre = require('hardhat');

const zero = '0x0000000000000000000000000000000000000000';

// Declare all mainnet addresses here

const aTokenMaticContract = '0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4';
const wmatic = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';
const wETHGateway = '0xbEadf48d62aCC944a06EEaE0A9054A90E5A7dc97';
const maticLendingPool = '0x8dff5e27ea6b7ac08ebfdf9eb090f32ee9a30fcf';
const bonusRewards = '0x357D51124f59836DeD84c8a1730D72B749d8BC23';

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

// Libraru deployments:

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

async function AaveVaultDeploy () {
    // We get the contract to deploy
    const Vault = await ethers.getContractFactory('EonsMATICAaveVault');
    console.log('Deploying AAVE Vault...');
    // (_wmatic, _bonusAddress, _devVault, _aTokenAddress)
    vault = await Vault.deploy(wmatic, bonusRewards, devVault, aTokenMaticContract);
    await vault.deployed();
    console.log('Vault deployed to:', vault.address);
}

// router initializer needs: lendingprovider, vault
async function AaveRouterDeploy () {
    // We get the contract to deploy
    const Router = await ethers.getContractFactory('EonsAaveRouter');
    console.log('Deploying AAVE Router...');
    router = await Router.deploy(vault.address, wETHGateway);
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
    eaEons = await EaEons.deploy(aTokenMaticContract, vault.address);
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
    await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await eaEonsDeploy();
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupVault() {
    // const Cont = await ethers.getContractFactory('iEonsController');
    // const cont = await Cont.attach(eonsControllerAddress);
    // await vault.addAdmin('0x5061A60D2893fbbC5a06c88B9b0EF8a423442a55');
    // await vault.pause();
    // await vault.setRouterAddress(router.address);
    // await vault.editAsset(eaEonsAddress, maticLendingPool);
    // await vault.unPause();
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
// const Vault = await ethers.getContractFactory('EonsAaveVault');
// or
// const Vault = await ethers.getContractFactory('EonsMATICAaveVault');
// const vault = await Vault.attach('');

// const eaEons = await ethers.getContractFactory('eaEons');
// const eaeons = await eaEons.attach('');

// (await eaeons.eTotalSupply()).toString();
// (await eaeons.totalSupply()).toString();
// (await eaeons.getA()).toString();
// (await eaeons.getCurrentIndex()).toString();
// (await eaeons.getNewIndex()).toString();
// (await vault.devA('0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4')).toString();

// await eaeons.add();

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
// https://polygonscan.com/address/0x034ADB2853bCd9EAa2A6059dB8b676385C6a1caa#code

// Router
// npx hardhat verify --contract contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter <address> --network Mumbai
// on Polygonscan:
// https://polygonscan.com/address/0xD502bC719a0DB6Ab57eeAf45Fe29B6e4dcabc8ac#code

// eaEons
// npx hardhat verify --contract contracts/main/tokens/eaEons.sol:eaEons <address> --network Mumbai
// on Polygonscan:
// https://polygonscan.com/address/0x5A8aCC41da94a173586C740cc3d9559a0b08feC7#code

// npx hardhat verify \
// --network Polygon \
// --constructor-args scripts/args/vault-args.js \
// --contract contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault \
// 0x56eBD2d571C836017968Bc8D8BF3cb8109020F46

// npx hardhat verify \
// --network Polygon \
// --constructor-args scripts/args/vault-args.js \
// --contract contracts/main/vaults/EonsMATICAaveVault.sol:EonsMATICAaveVault \
// 0x034ADB2853bCd9EAa2A6059dB8b676385C6a1caa

// USDC eaEons address 0x9B05DA3EC5eF18D7932056324401Da8B3f0E0335