require('dotenv').config();
const hre = require('hardhat');

const wethAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c';
const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const aaveLendingPoolProviderAddress = '0x88757f2f99175387ab4c6a4b3067c77a695b0349';
const aavePriceOracleAddress = '0xb8be51e6563bb312cbb2aa26e352516c25c26ac1';

let eonsAddress = '0x63f04014E7baF85ad8DcFa66863401334025Cf5b';
let eonsLpAddress = '0xa5C58e73F437039297d94a23dA28E4cB9b19eeeD';
let eEONSAddress = '0xca1014d7Caa632dF73f2BBEFc6b88f05D11E440e';
let feeApproverAddress = '0x16220134B896F8fE9f5047b0e945b6660646DB9E';
let wethGatewayAddress = '0xf3d629C1b949F76Fd7ce20A86cFA83Ba932Eb182';
let eonsQuickVaultProxyAddress = '';
let eonsQuickRouterProxyAddress = '';
let eonsAaveRouterProxyAddress = '';
let eonsAaveVaultProxyAddress = '';
let controllerProxyAddress = '';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'mainnet',
      address: eonsAddress
    })
  }
};

const eEONSVerify = async () => {
  if (eEONSAddress) {
    await hre.run('verify:verify', {
      address: eEONSAddress
    })
  }
}

const eonsLpVerify = async () => {
  if (eonsLpAddress) {
    await hre.run('verify:verify', {
      address: eonsLpAddress
    })
  }
}

const feeApproverVerify = async () => {
  if (feeApproverAddress) {
    await hre.run('verify:verify', {
      address: feeApproverAddress,
      constructorArguments: [
        eonsAddress,
        wethAddress,
        uniswapV2FactoryAddress
      ]
    })
  }
}

const wethGatewayAddressVerify = async () => {
  if (wethGatewayAddress) {
    await hre.run('verify:verify', {
      address: wethGatewayAddress,
      constructorArguments: [
        wethAddress
      ]
    })
  }
}

const eonsUniVaultVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xf8ae6281d3ac79a279c5cf27dd2900755c711b6f',
    contract: 'contracts/main/vaults/EonsUniswapVault.sol:EonsUniswapVault'
  })
}

const eonsUniRouterVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xa8c6cff73c9026d15f2c9e4900767830bcd86246',
    contract: 'contracts/main/routers/EonsUniswapRouter.sol:EonsUniswapRouter'
  })
}

const eonsAaveRouterVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xc92a901f348951cb0b13010c3134e25708f015db',
    contract: 'contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter'
  })
}

const eonsAaveVaultVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x34bb3921cd8c2bfe2be04a1add7ee5313443867e',
    contract: 'contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault'
  })
}

const eonsControllerVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xb5b9adb01ee5f337cc4b1b268892848587f01468',
    contract: 'contracts/main/Controller.sol:Controller'
  })
}

const main = async () => {
  // await eonsVerify();
  // await eonsLpVerify();
  // await eEONSVerify();
  // await feeApproverVerify();
  // await wethGatewayAddressVerify();
  // await eonsUniVaultVerify();
  // await eonsUniRouterVerify();
  // await eonsAaveRouterVerify();
  // await eonsAaveVaultVerify();
  // await eonsControllerVerify();
};

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
