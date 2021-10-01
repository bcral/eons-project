require('dotenv').config();
const hre = require('hardhat');
const fs = require('fs');
const { Wallet } = require('ethers');

// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

let wethAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c';

const aaveLendingPoolProviderAddress = '0x88757f2f99175387ab4c6a4b3067c77a695b0349';  // should be updated with getting latest lending pool address from lending pool provider contract
const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const uniswapV2RouterAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const aavePriceOracleAddress = '0xb8be51e6563bb312cbb2aa26e352516c25c26ac1';
const devAddr = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';
const treasury = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';

let eonsAddress = '0x63f04014E7baF85ad8DcFa66863401334025Cf5b';
let eonsLpAddress = '0xa5C58e73F437039297d94a23dA28E4cB9b19eeeD';
let eEONSAddress = '0xca1014d7Caa632dF73f2BBEFc6b88f05D11E440e';
let feeApproverAddress = '0x16220134B896F8fE9f5047b0e945b6660646DB9E';
let wethGatewayAddress = '0xf3d629C1b949F76Fd7ce20A86cFA83Ba932Eb182';
let eonsUniVaultProxyAddress = '0x848fA2351E98D6501bD61B11Db0eA19c8c4328dC';
let eonsUniRouterProxyAddress = '0xfd8d593492A709f8C357f5464C65ff420aE50bf5';
let eonsAaveRouterProxyAddress = '0x89681767365BcA8A4fDF511c3C8D6C06E2bF2cef';
let eonsAaveVaultProxyAddress = '0x22F1efCE833652651922E81804E9942aac7B217C';
let controllerProxyAddress = '0xdfb157F343A01497D9cc8B14Da29B0B80b1aDD27';

const eonsETHArtifact = './artifacts/contracts/main/tokens/EEONS.sol/EEONS.json';
const eonsArtifact = './artifacts/contracts/main/tokens/Eons.sol/Eons.json';
const eonsAaveRouterArtifact = './artifacts/contracts/main/routers/EonsAaveRouter.sol/EonsAaveRouter.json';

const unpackArtifact = (artifactPath) => {
  let contractData = JSON.parse(fs.readFileSync(artifactPath));
  const contractBytecode = contractData["bytecode"];
  const contractABI = contractData["abi"];
  const constructorArgs = contractABI.filter((itm) => {
    return itm.type == "constructor";
  });

  let constructorStr;

  if (constructorArgs.length < 1) {
    constructorStr = "    -- No constructor arguments -- ";
  } else {
    constructorJSON = constructorArgs[0].inputs;
    constructorStr = JSON.stringify(
      constructorJSON.map((c) => {
        return {
          name: c.name,
          type: c.type,
        };
      })
    );
  }

  return {
    abi: contractABI,
    bytecode: contractBytecode,
    contractName: contractData.contractName,
    constructor: constructorStr,
  };
};

let provider;

if (process.env.NETWORK === 'kovan') {
  provider = hre.ethers.getDefaultProvider('kovan');
} else if (process.env.NETWORK === 'mainnet') {
  provider = hre.ethers.getDefaultProvider('homestead');
} else if (process.env.NETWORK === 'bsctest') {
  provider = new hre.ether.providers.JsonRpcProvider('https://data-seed-prebsc-1-s1.binance.org:8545');
} else if (process.env.NETWORK === 'bscmain') {
  provider = new hre.ether.providers.JsonRpcProvider('https://bsc-dataseed.binance.org/');
}

const wallet = new Wallet(process.env.PRIVATE_KEY);

const deploy = async (tokenName, initializerName, args = []) => {
  try {
    const SmartContract = await hre.ethers.getContractFactory(tokenName);
    const smartContract = await hre.upgrades.deployProxy(SmartContract, args, {initializer: initializerName});
    await smartContract.deployed();
    console.log(`[deploy] deployed ${tokenName} proxy to => `, smartContract.address);
    if (tokenName === 'EonsAaveVault') {
      console.log('adding pools to EonsAaveVault...');
      await smartContract.add('eBTC', eEONSAddress, 0, 0);
      await smartContract.add('eETH', eEONSAddress, 1000, 0);
      console.log('added pools to EonsAaveVault');
      const { abi, bytecode } = unpackArtifact(eonsETHArtifact);
      const eonsETHContract = new hre.ethers.Contract(eEONSAddress, abi, wallet.connect(provider));
      console.log('adding EonsAaveVault as a minter to eonsETH...');
      eonsETHContract.addMinter(smartContract.address);
      console.log('added EonsAaveVault as a minter to eonsETH.');
      const { abi: aaveRouterAbi } = unpackArtifact(eonsAaveRouterArtifact)
      const aaveRouter = new hre.ethers.Contract(eonsAaveRouterProxyAddress, aaveRouterAbi, wallet.connect(provider));
      await aaveRouter.setVault(smartContract.address);
    }
    if (tokenName === 'EonsAaveRouter') {
      console.log('adding assets to EonsAaveRouter...');
      await smartContract.addAaveToken('0xD1B98B6607330172f1D991521145A22BCe793277', '0x62538022242513971478fcC7Fb27ae304AB5C29F', 0);  // btc aave tokens
      await smartContract.addAaveToken('0xd0A1E359811322d97991E03f863a0C30C2cF029C', '0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347', 1);  // eth aave tokens
      console.log('added assets to EonsAaveRouter.');
    }
    if (tokenName === 'Controller') {
      console.log('adding controller as a minter to eons token...');
      const { abi, bytecode } = unpackArtifact(eonsArtifact);
      const eonsContract = new hre.ethers.Contract(eonsAddress, abi, wallet.connect(provider));
      eonsContract.addMinter(smartContract.address);
      console.log('added controller as a minter to eons token.');
    }
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
  const [deployer] = await hre.ethers.getSigners();
  console.log('aj : ***** Account balance: ', (await deployer.getBalance()).toString());
  const Eons = await hre.ethers.getContractFactory('Eons');
  eons = await Eons.deploy();
  await eons.deployed();
  console.log('eons deployed to:', eons.address);
};

const deployEonsLPToken = async () => {
  const EonsLP = await hre.ethers.getContractFactory('EonsLP');
  eonsLP = await EonsLP.deploy();
  await eonsLP.deployed();
  console.log('eonsLP deployed to:', eonsLP.address);
};

const deployEEonsToken = async () => {
  const EEONS = await hre.ethers.getContractFactory('EEONS');
  eEONS = await EEONS.deploy();
  await eEONS.deployed();
  console.log('eEONS deployed to:', eEONS.address);
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
  feeApprover = await FeeApprover.deploy(eonsAddress, wethAddress, uniswapV2FactoryAddress);
  await feeApprover.deployed();
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
        eonsAddress,
        aavePriceOracleAddress
      ]);
    }
  }
};

const main = async () => {
  // await deployEonsToken();
  // await deployEonsLPToken();
  // await deployEEonsToken();
  // await deployFeeApprover();
  // await deployWETHGateway();
  // await deployEonsUniVault();
  // await deployEonsUniRouter();
  // await deployEonsAaveRouter();
  // await deployEonsAaveVault();
  await deployController();
};

main();
