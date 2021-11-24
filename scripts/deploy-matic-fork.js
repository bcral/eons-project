require('dotenv').config();
const hre = require('hardhat');

// Testnet deployment address
const addr1 = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const zero = '0x0000000000000000000000000000000000000000';

// Declare all mainnet addresses here

const aTokenMaticContract = '0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4';
const wmatic = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';
const wETHGateway = '0xbEadf48d62aCC944a06EEaE0A9054A90E5A7dc97';
const maticLendingPool = '0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf';
const bonusRewards = '0x357D51124f59836DeD84c8a1730D72B749d8BC23';

// Declare all globals that will need access elseware:
let aaveLendingPoolProviderAddress = '0xd05e3E715d945B59290df0ae8eF85c1BdB684744'; 
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
let eons;

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
    // vault = await ethers.getContractFactory('EonsAaveVault');
    console.log('Deploying AAVE Vault...');
    // vault = await AaveVault.deploy();
    vault = await deploy('EonsERC20AaveVault', 'initializerFunction', [wmatic, bonusRewards, devVault]);
    // await vault.initialize([wmatic, bonusRewards, devVault]);
    // await vault.deployed();
    // aaveVaultAddress = vault.address;
    // console.log('AAVE Vault deployed to:', aaveVaultAddress);
}

// router initializer needs: lendingprovider, vault
async function AaveRouterDeploy () {
    // We get the contract to deploy
    // router = await ethers.getContractFactory('EonsAaveRouter');
    console.log('Deploying AAVE Router...');
    router = await deploy('EonsAaveRouter', 'initialize', [vault.address, wETHGateway]);
    // await router.deployed();
    // aaveRouterAddress = router.address;
    // console.log('AAVE Router deployed to:', aaveRouterAddress);
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
    eons = await Eons.deploy();
    await eons.deployed();
    // eonsAddress = eons.address
    console.log('Eons deployed to:', eons.address);
}

// deploy all contracts with this function
async function main () {
    // We get the contract to deploy
    await EonsControllerDeploy();
    await DSMathDeploy();
    await EonsDeploy();
    await AaveVaultDeploy();
    await AaveRouterDeploy();
    await eaEonsDeploy();
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupVault() {
    await vault.setRouterAddress(router.address);
    await vault.editAsset(0, zero, eaEonsAddress, aTokenMaticContract, maticLendingPool);
    console.log('Vault setup complete...');
}

// ADD ROUTER AS FIRST SETUP STEP
async function setupEaEons() {
    // await eaEons.setDeploymentValues(aTokenMaticContract, aaveVaultAddress);
}

// setup all contracts with this function
async function setup () {
    await setupVault();
    await setupEaEons();

    console.log('Setup complete...');
}
  
async function runEverything() {
    await main();
    await setup();
}

runEverything();

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
// npx hardhat verify --contract contracts/peripheries/libraries/DSMath.sol:DSMath <address> --network maticMainnet
// on Polygonscan:
// https://polygonscan.com/address/0x2d93473AdD602006C5E4280458A426E1DDc75c5d#code

// Vault
// npx hardhat verify --contract contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault <address> --network maticMainnet
// on Polygonscan:
// https://polygonscan.com/address/0x9390064255EDb1ac6C994D7A0A43Ede5Ce90E1DF#code

// Router
// npx hardhat verify --contract contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter <address> --network maticMainnet
// on Polygonscan:
// https://polygonscan.com/address/0xfec2E6b5b1B8ca39F3535D4eC8dd38B6ceF79F7A#code


// eaEons
// npx hardhat verify --contract contracts/main/tokens/eaEons.sol:eaEons <address> --network maticMainnet
// on Polygonscan:
// https://polygonscan.com/address/0x564A8BF80268f1E8ACD3cB7847D05B7EB5d4c593#code
