require('dotenv').config();
const hre = require('hardhat');

// Testnet deployment address
const addr1 = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const zero = '0x0000000000000000000000000000000000000000';

// Declare all mainnet addresses here

const aTokenMaticContract = '0xF45444171435d0aCB08a8af493837eF18e86EE27';
const wmatic = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889';
const wETHGateway = '0xee9eE614Ad26963bEc1Bec0D2c92879ae1F209fA';
const maticLendingPool = '0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf';
const bonusRewards = '0x357D51124f59836DeD84c8a1730D72B749d8BC23';

// Declare all globals that will need access elseware:
let lendingPool = '0x9198F13B08E299d85E096929fA9781A1E3d5d827'; 
// David's MATIC address for simulating Dev withdrawals
// Actually just a dummy testnet address
let devVault = '0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199';

let dsmathAddress;
let eaEonsAddress;
let eonsAddress;
let aaveVaultAddress;
let aaveRouterAddress;
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
    const EonsController = await ethers.getContractFactory('EonsController');
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
    // We get the contract to deploy
    await DSMathDeploy();
    await EonsControllerDeploy();
    // await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await eaEonsDeploy();
}
  
async function runEverything() {
    await main();
}

runEverything();
