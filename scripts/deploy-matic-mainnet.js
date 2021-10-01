require('dotenv').config();
const hre = require('hardhat');
const fs = require('fs');
const { Wallet } = require('ethers');

// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

const wethAddress = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';

const aaveLendingPoolProviderAddress = '0xd05e3E715d945B59290df0ae8eF85c1BdB684744';  // should be updated with getting latest lending pool address from lending pool provider contract
const quickswapV2FactoryAddress = '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32';
const quickswapV2RouterAddress = '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32';
const aavePriceOracleAddress = '0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d';
const devAddr = '0x4Bf18d1fD330C5c32eAaB1C673593255EBA546af';
const treasury = '0x4Bf18d1fD330C5c32eAaB1C673593255EBA546af';

let eonsAddress = '0x531B8bf27771085f92E77646094408e1E743aa18';
let eonsLpAddress = '0xA6057eAc9Ee8ca240789a5a11B35a8CC266365dd';
let eEONSAddress = '0xfB144a0952f179FCD58731c21f78613613010552';
let feeApproverAddress = '0xed8ed6e6072C80A40781FeB70cA4771978d19eD5';
let wethGatewayAddress = '0x4e9820e9D254d87D276B1949F79b5874A0f1CB5B';
let eonsQuickVaultProxyAddress = '0x38eB700D0158caa358362c15Df80b9c4632f511C';
let eonsQuickRouterProxyAddress = '0x43aD208F63fEF4A3246AFCBF2C46652a57818235';
let eonsAaveRouterProxyAddress = '0xD325786c21C09E1b44331084A671506FF2102FF2';
let eonsAaveVaultProxyAddress = '0x0F93D224C9Dbf32Da34a80ce98Cf6a8bB5e7740d';
let controllerProxyAddress = '0x8055e175719544233b7da603d5c28d5C1d828AF9';

const eEONSArtifact = './artifacts/contracts/main/tokens/EEONS.sol/EEONS.json';
const eonsAaveRouterArtifact = './artifacts/contracts/main/routers/EonsAaveRouter.sol/EonsAaveRouter.json';
const eonsArtifact = './artifacts/contracts/main/tokens/Eons.sol/Eons.json';

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
  provider = new hre.ethers.providers.JsonRpcProvider('https://data-seed-prebsc-1-s1.binance.org:8545');
} else if (process.env.NETWORK === 'bscmain') {
  provider = new hre.ethers.providers.JsonRpcProvider('https://bsc-dataseed.binance.org/');
} else if (process.env.NETWORK === 'maticmain') {
  provider = new hre.ethers.providers.JsonRpcProvider('https://rpc-mainnet.maticvigil.com');
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
      await smartContract.add('eMATIC', eEONSAddress, 1000, 0);
      console.log('added pools to EonsAaveVault');
      const { abi, bytecode } = unpackArtifact(eEONSArtifact);
      const eonsETHContract = new hre.ethers.Contract(eEONSAddress, abi, wallet.connect(provider));
      console.log('adding EonsAaveVault as a minter to eonsETH...');
      await eonsETHContract.addMinter(smartContract.address);
      console.log('added EonsAaveVault as a minter to eonsETH.');
      const { abi: aaveRouterAbi } = unpackArtifact(eonsAaveRouterArtifact)
      const aaveRouter = new hre.ethers.Contract(eonsAaveRouterProxyAddress, aaveRouterAbi, wallet.connect(provider));
      await aaveRouter.setVault(smartContract.address);
    }
    if (tokenName === 'EonsAaveRouter') {
      console.log('adding assets to EonsAaveRouter...');
      await smartContract.addAaveToken('0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6', '0x28424507fefb6f7f8E9D3860F56504E4e5f5f390', 0);  // btc aave tokens
      await smartContract.addAaveToken('0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4', 1);  // matic aave tokens
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
  const EEons = await hre.ethers.getContractFactory('EEONS');
  eEons = await EEons.deploy();
  await eEons.deployed();
  console.log('eEons deployed to:', eEons.address);
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

const deployEonsQuickVault = async () => {
  if (eonsQuickVaultProxyAddress) {
    await upgrade('EonsQuickSwapVault', eonsQuickVaultProxyAddress);
  } else {
    await deploy('EonsQuickSwapVault', 'initialize', [eonsLpAddress, eonsAddress, devAddr, devAddr]);
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
  feeApprover = await FeeApprover.deploy(eonsAddress, wethAddress, quickswapV2FactoryAddress);
  await feeApprover.deployed();
  console.log('feeApprover deployed to:', feeApprover.address);
};

const deployEonsQuickRouter = async () => {
  if (eonsQuickRouterProxyAddress) {
    await upgrade('EonsQuickSwapRouter', eonsQuickRouterProxyAddress);
  } else {
    await deploy('EonsQuickSwapRouter', 'initialize', [eonsAddress, wethAddress, quickswapV2FactoryAddress, feeApproverAddress, eonsQuickVaultProxyAddress]);
  }
};

const deployController = async () => {
  if (controllerProxyAddress) {
    await upgrade('Controller', eonsQuickRouterProxyAddress);
  } else {
    if (!!eonsAddress && !!eonsAaveVaultProxyAddress && !!eonsQuickVaultProxyAddress && !!eonsAaveRouterProxyAddress && !!eonsQuickRouterProxyAddress) {
      await deploy('Controller', 'initialize', [
        eonsAaveVaultProxyAddress,
        eonsQuickVaultProxyAddress,
        eonsAaveRouterProxyAddress,
        eonsQuickRouterProxyAddress,
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
  // await deployEonsQuickVault();
  // await deployEonsQuickRouter();
  // await deployEonsAaveRouter();
  // await deployEonsAaveVault();
  await deployController();
};

main();
