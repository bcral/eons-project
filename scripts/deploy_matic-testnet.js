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

// Hardhat deployment function for adding initializer values
const deploy = async (tokenName, initializerName, args = []) => {
    try {
      const SmartContract = await hre.ethers.getContractFactory(tokenName);
      const smartContract = await hre.upgrades.deployProxy(SmartContract, args, {initializer: initializerName});
      await smartContract.deployed();
      console.log(`[deploy] deployed ${tokenName} proxy to => `, smartContract.address);
      return smartContract;
    } catch (error) {
      console.log('[deploy] error => ', error);
    }
  };

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
    console.log('Deploying AAVE Vault...');
    vault = await deploy('EonsAaveVault', 'initializerFunction', [wmatic, bonusRewards, devVault]);
}

// router initializer needs: lendingprovider, vault
async function AaveRouterDeploy () {
    // We get the contract to deploy
    console.log('Deploying AAVE Router...');
    router = await deploy('EonsAaveRouter', 'initialize', [vault.address, wETHGateway]);
}

// initialize(address _aaveVault, address _aaveRouter, address _devVault)
async function EonsControllerDeploy () {
    // We get the contract to deploy
    const EonsController = await ethers.getContractFactory('iEonsController');
    console.log('Deploying Controller...');
    const eonsController = await EonsController.deploy();
    await eonsController.initialize();
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
    await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await eaEonsDeploy();
}

// // -setup(addAsset, add vault/router addresses, etc)
// // -Vault
// async function initVault() {
//     const Vault = await ethers.getContractFactory('EonsAaveVault');
//     vault = await Vault.attach(aaveVaultAddress);
// }
// // -eaEons
// async function initEaEons() {
//     const EAEONS = await ethers.getContractFactory('eaEons');
//     eaeons = await EAEONS.attach(eonsAddress);
// }
// // -Router
// async function initRouter() {
//     const Router = await ethers.getContractFactory('EonsAaveRouter');
//     router = await Router.attach(aaveRouterAddress);
// }

// ADD ROUTER AS FIRST SETUP STEP
async function setupVault() {
    await vault.setRouterAddress(router.address);
    await vault.editAsset(0, zero, eaEonsAddress, aTokenMaticContract, maticLendingPool);
    console.log('Vault setup complete...');
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupEaEons() {
    // await eaeons.setDeploymentValues(aTokenMaticContract, aaveVaultAddress);
}

// setup all contracts with this function
async function setup () {
    // await initVault();
    // await initEaEons();
    // await initRouter();

    await setupVault();
    await setupEaEons();

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
// const vault = await Vault.attach('');

// const eaEons = await ethers.getContractFactory('eaEons');
// const eaeons = await eaEons.attach('');
// await eaeons.setDeploymentValues(aToken, vault);

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
// https://mumbai.polygonscan.com/address/0x561Bb4b1A206714b933415Bb04eF560f6444189A#code

// Vault
// npx hardhat verify --contract contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault <address> --network Mumbai
// on Polygonscan:
// https://mumbai.polygonscan.com/address/0x03C31A0DAb473F8B23Cf63079945144772E2b529#code

// Router
// npx hardhat verify --contract contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter <address> --network Mumbai
// on Polygonscan:
// https://mumbai.polygonscan.com/address/0xBd1Ce7C5D13624687F9395AE8D3d1Df196e9D844#code

// eaEons
// npx hardhat verify --contract contracts/main/tokens/eaEons.sol:eaEons <address> --network Mumbai
// on Polygonscan:
// https://mumbai.polygonscan.com/address/0xCFcF03dc822568057830D2923e94a1Ee2300b544#code