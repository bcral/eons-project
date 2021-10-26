require('dotenv').config();
const hre = require('hardhat');
const fs = require('fs');
const { Wallet } = require('ethers');

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
} else if (process.env.NETWORK == 'main-fork') {
  wethAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
}

// For use as a placeholder
const zeroContract = '0x0000000000000000000000000000000000000000';
const usdcAToken = '0xbcca60bb61934080951369a648fb03df4f96263c';

const aaveLendingPoolProviderAddress = '0x88757f2f99175387ab4c6a4b3067c77a695b0349';  // should be updated with getting latest lending pool address from lending pool provider contract
const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const uniswapV2RouterAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const aavePriceOracleAddress = '0xb8be51e6563bb312cbb2aa26e352516c25c26ac1';
const curveV2Contract = '0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490';
const curveLiquidityGauge = '0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A';
const curve3Pool = '0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7';
const devAddr = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';
const treasury = '0xD01A3bA68E7acdD8A5EBaB68d6d6CfA313fec272';

let eonsAddress = '0xEf538B1604B0CcC265a99B295F2FeD4AD9dCddCf';
let eaEonsAddress = '';
let eonsAaveRouterAddress = '';
let eonsAaveVaultAddress = '';
let controllerProxyAddress = '';

const eaEonsArtifact = './artifacts/contracts/tokens/eaEons.sol/eaEons.json';
const eonsArtifact = './artifacts/contracts/tokens/Eons.sol/Eons.json';

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
} else if (process.env.NETWORK === 'main-fork') {
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
    // if (tokenName === 'EonsAaveVault') {
    //   console.log('adding pools to EonsAaveVault...');
    //   await smartContract.add('eBTC', eonsETHAddress, 0, 0);
    //   await smartContract.add('eETH', eonsETHAddress, 1000, 0);
    //   console.log('added pools to EonsAaveVault');
    //   const { abi, bytecode } = unpackArtifact(eonsETHArtifact);
    //   const eonsETHContract = new hre.ethers.Contract(eonsETHAddress, abi, wallet.connect(provider));
    //   console.log('adding EonsAaveVault as a minter to eonsETH...');
    //   eonsETHContract.addMinter(smartContract.address);
    //   console.log('added EonsAaveVault as a minter to eonsETH.');
    // }
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
  const Eons = await ethers.getContractFactory("Eons");
  const eons = await Eons.deploy();
  await eons.deployed();
  eonsAddress = eons.address;
  console.log('eons deployed to:', eons.address);
};

const deployEonsAaveVault = async () => {
  const EonsAaveVault = await ethers.getContractFactory("EonsAaveVault");
  const eonsAaveVault = await EonsAaveVault.deploy();
  await eonsAaveVault.deployed();
  await eonsAaveVault.initialize(eonsAddress);
  eonsAaveVaultAddress = eonsAaveVault.address;
  console.log("EonsAaveVault deployed to:", eonsAaveVault.address);
};

const deployEaEonsToken = async () => {
  const EaEons = await ethers.getContractFactory("eaEons");
  const eaEons = await EaEons.deploy(usdcAToken, eonsAaveVaultAddress);
  await eaEons.deployed();
  eaEonsAddress = eaEons.address;
  console.log('eaEons deployed to:', eaEons.address);
};

const deployEonsAaveRouter = async () => {
  const EonsAaveRouter = await ethers.getContractFactory("EonsAaveRouter");
  const eonsAaveRouter = await EonsAaveRouter.deploy();
  await eonsAaveRouter.deployed();
  await eonsAaveRouter.initialize(aaveLendingPoolProviderAddress, eonsAaveVaultAddress);
  eonsAaveRouterAddress = eonsAaveRouter.address;
  console.log("EonsAaveRouter deployed to:", eonsAaveRouter.address);
};

const deployController = async () => {
  if (controllerProxyAddress) {
    await upgrade('Controller', eonsUniRouterProxyAddress);
  } else {
    if (!!eonsAddress && !!eonsAaveVaultProxyAddress && !!eonsUniVaultProxyAddress && !!eonsAaveRouterProxyAddress && !!eonsUniRouterProxyAddress && !!eonsCurveRouterProxyAddress) {
      await deploy('Controller', 'initialize', [
        eonsAaveVaultProxyAddress,
        eonsUniVaultProxyAddress,
        eonsAaveRouterProxyAddress,
        eonsAddress,
      ]);
    }
  }
};

const main = async () => {
  await deployEonsToken();
  await deployEonsAaveVault();
  await deployEaEonsToken();
  await deployEonsAaveRouter();
  // await deployController();
};

main();