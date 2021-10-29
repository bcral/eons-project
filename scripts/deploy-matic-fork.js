require('dotenv').config();
const hre = require('hardhat');

// Testnet deployment address
const addr1 = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const zero = '0x0000000000000000000000000000000000000000';

// Declare all mainnet addresses here

const aTokenMaticContract = '0x8df3aad3a84da6b69a4da8aec3ea40d9091b2ac4';
const wmatic = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';
const wETHGateway = '0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04';

// Declare all globals that will need access elseware:
let aaveLendingPoolProviderAddress = '0x88757f2f99175387ab4c6a4b3067c77a695b0349'; 
// David's MATIC address for simulating Dev withdrawals
let devVault = '0x09Da980E4Ad37E340183eB71D76dc1eFFB4Dd1cA';

let dsmathAddress;
let eaEonsAddress;
let eonsAddress;
let aaveVaultAddress;
let aaveRouterAddress;
let eonsControllerAddress;

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
    const AaveVault = await ethers.getContractFactory('EonsAaveVault');
    console.log('Deploying AAVE Vault...');
    const aaveVault = await AaveVault.deploy();
    await aaveVault.initialize();
    await aaveVault.deployed();
    aaveVaultAddress = aaveVault.address;
    console.log('AAVE Vault deployed to:', aaveVaultAddress);
}

// router initializer needs: lendingprovider, vault
async function AaveRouterDeploy () {
    // We get the contract to deploy
    const AaveRouter = await ethers.getContractFactory('EonsAaveRouter');
    console.log('Deploying AAVE Router...');
    const aaveRouter = await AaveRouter.deploy();
    await aaveRouter.initialize(aaveLendingPoolProviderAddress, aaveVaultAddress, wmatic, wETHGateway);
    await aaveRouter.deployed();
    aaveRouterAddress = aaveRouter.address;
    console.log('AAVE Router deployed to:', aaveRouterAddress);
}

// initialize(address _aaveVault, address _aaveRouter, address _devVault)
async function EonsControllerDeploy () {
    // We get the contract to deploy
    const EonsController = await ethers.getContractFactory('iEonsController');
    console.log('Deploying Controller...');
    const eonsController = await EonsController.deploy();
    await eonsController.initialize(aaveVaultAddress, aaveRouterAddress, devVault);
    await eonsController.deployed();
    eonsControllerAddress = eonsController.address;
    console.log('Controller deployed to:', eonsControllerAddress);
}

// Token deployments:

async function eaEonsDeploy () {
    // We get the contract to deploy
    const EaEons = await ethers.getContractFactory('eaEons');
    console.log('Deploying eaEons...');
    const eaEons = await EaEons.deploy(aTokenMaticContract, aaveVaultAddress, eonsControllerAddress);
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
    // We get the contract to deploy
    await DSMathDeploy();
    await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await EonsControllerDeploy();
    await eaEonsDeploy();
}
  
    //main();
    // .then(() => process.exit(0))
    // .catch(error => {
    //   console.error(error);
    //   process.exit(1);
    // });


// Declare all globals for testing
let vault;
let eaeons;
let router;

// -setup(addAsset, add vault/router addresses, etc)
// -Vault
async function initVault() {
    const Vault = await ethers.getContractFactory('EonsAaveVault');
    vault = await Vault.attach(aaveVaultAddress);
}
// -eaEons
async function initEaEons() {
    const eaEons = await ethers.getContractFactory('eaEons');
    eaeons = await eaEons.attach(eonsAddress);
}
// -Router
async function initRouter() {
    const Router = await ethers.getContractFactory('EonsAaveRouter');
    router = await Router.attach(aaveRouterAddress);
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupVault() {
    await vault.setRouterAddress(aaveRouterAddress);
    await vault.editAsset(0, zero, eonsAddress, aTokenMaticContract);
}


// setup all contracts with this function
async function setup () {
    await initVault();
    await initEaEons();
    await initRouter();

    await setupVault();

    console.log('Setup complete...');
}
  
async function runEverything() {
    await main();
    await setup();
}

runEverything();

// Then...(copy/paste into npx hardhat console --network localhost):
// const Vault = await ethers.getContractFactory('EonsAaveVault');
// vault = await Vault.attach('<deployed-vault-address>');
// await vault.depositMATIC({value: '5000000000000000000'});