require('dotenv').config();
const hre = require('hardhat');

// Testnet deployment address
const addr1 = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const zero = '0x0000000000000000000000000000000000000000';

// Declare all testnet addresses here

const QSRouter = '0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff';

const aTokenMaticContract = '0xF45444171435d0aCB08a8af493837eF18e86EE27';
const aTokenUSDCContract = '0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9';
const wmatic = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889';
const wETHGateway = '0xee9eE614Ad26963bEc1Bec0D2c92879ae1F209fA';
const maticLendingPool = '0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf';
const bonusRewards = '0x357D51124f59836DeD84c8a1730D72B749d8BC23';

// USDC address on Polygon
const nativeAsset1 = '0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e';

// Declare all globals that will need access elseware:
let lendingPool = '0x9198F13B08E299d85E096929fA9781A1E3d5d827'; 
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
    vault = await Vault.deploy(wmatic, bonusRewards, devVault, aTokenUSDCContract, nativeAsset1, lendingPool, QSRouter);
    await vault.deployed();
    console.log('Vault deployed to:', vault.address);
}

// router for ERC20 interactions
// NEEDS VAULT INTEGRATED TO USSE
async function AaveRouterDeploy () {
    // We get the contract to deploy
    const Router = await ethers.getContractFactory('EonsERC20AaveRouter');
    console.log('Deploying AAVE Router...');
    router = await Router.deploy(wETHGateway);
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
    eaEons = await EaEons.deploy(aTokenUSDCContract, vault.address);
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
    await vault.pause();
    await vault.setRouterAddress(router.address);
    await vault.editAsset(lendingPool);
    await vault.setETokenAddress(eaEonsAddress);
    await vault.unPause();
    await router.pause();
    await router.setVault(nativeAsset1, vault.address);
    await router.unPause();

    // // Populate with account containing Polygon USDC
    // const accountToInpersonate = "0x2b56089fd96537e5A59435384c83D847D4C68aAe";

    // await hre.network.provider.request({
    //     method: "hardhat_impersonateAccount",
    //     params: [accountToInpersonate],
    // });

    // const me = await ethers.getSigner(accountToInpersonate);

    // const USDC = await ethers.getContractFactory('ERC20');
    // const usdc = await USDC.attach(nativeAsset1);

    // await usdc.connect(me).approve(router.address, 2000000);
    // await vault.connect(me).deposit(2000000);
    // console.log('Vault setup complete...');
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

// const Vault = await ethers.getContractFactory('EonsERC20AaveVault');
// const vault = await Vault.attach('');

// const Router = await ethers.getContractFactory('EonsERC20AaveRouter');
// const router = await Router.attach('');

// const eaEons = await ethers.getContractFactory('eaEons');
// const eaeons = await eaEons.attach('');

// const USDC = await ethers.getContractFactory('ERC20');
// const usdc = await USDC.attach('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174');

// (await eaeons.eTotalSupply()).toString();
// (await eaeons.totalSupply()).toString();
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
// --constructor-args scripts/args/vault-args.js \
// --contract contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault \
// 0x56eBD2d571C836017968Bc8D8BF3cb8109020F46

// npx hardhat verify \
// --network Polygon \
// --constructor-args scripts/args/vault-args.js \
// --contract contracts/main/vaults/EonsMATICAaveVault.sol:EonsMATICAaveVault \
// 0x9D13DA4c2377EFa3F0Ccb82C24959B709B490409

// USDC eaEons address 0x9B05DA3EC5eF18D7932056324401Da8B3f0E0335

// Other acct: 0x8D6f2449833AF09c29652B759147a83Ff44fee46