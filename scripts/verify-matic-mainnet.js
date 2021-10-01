require('dotenv').config();
const hre = require('hardhat');

const wethAddress = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';
const quickswapV2FactoryAddress = '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32';
const aaveLendingPoolProviderAddress = '0xd05e3E715d945B59290df0ae8eF85c1BdB684744';
const aavePriceOracleAddress = '0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d';

let eonsAddress = '0x531B8bf27771085f92E77646094408e1E743aa18';
let eonsLpAddress = '0xA6057eAc9Ee8ca240789a5a11B35a8CC266365dd';
let eEONSAddress = '0xfB144a0952f179FCD58731c21f78613613010552';
let feeApproverAddress = '0xed8ed6e6072C80A40781FeB70cA4771978d19eD5';
let wethGatewayAddress = '0x4e9820e9D254d87D276B1949F79b5874A0f1CB5B';
let eonsQuickVaultProxyAddress = '0x38eB700D0158caa358362c15Df80b9c4632f511C';
let eonsQuickRouterProxyAddress = '0x29a795C2Ab1B0330C5a8a27E84EC6a5f17f25026';
let eonsAaveRouterProxyAddress = '0x54fc6A19FF18EC7BC740444D9215f601B9Ef457b';
let eonsAaveVaultProxyAddress = '0xfc8dE9c2d105bd71f6b93d6Cfa4C178DE2e2a67b';
let controllerProxyAddress = '0x4Dc6b8310335E6B49bE6212057aABDe213C762Df';

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
        quickswapV2FactoryAddress
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

const eonsQuickVaultVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xef538b1604b0ccc265a99b295f2fed4ad9dcddcf',
    contract: 'contracts/main/vaults/EonsQuickSwapVault.sol:EonsQuickSwapVault'
  })
}

const eonsQuickRouterVerify = async () => {
  await hre.run('verify:verify', {
    address: '0xca1014d7caa632df73f2bbefc6b88f05d11e440e',
    contract: 'contracts/main/routers/EonsQuickSwapRouter.sol:EonsQuickSwapRouter'
  })
}

const eonsAaveRouterVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x06919a3842dabfd62bda75f383001d4ff2b76ff1',
    contract: 'contracts/main/routers/EonsAaveRouter.sol:EonsAaveRouter'
  })
}

const eonsAaveVaultVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x51a68f45d2aa75044b6ae0bd43d0cc4d9750a7c2',
    contract: 'contracts/main/vaults/EonsAaveVault.sol:EonsAaveVault'
  })
}

const eonsControllerVerify = async () => {
  await hre.run('verify:verify', {
    address: '0x1d97b8f363609c1dc426358364dabf0bb052091c',
    contract: 'contracts/main/Controller.sol:Controller'
  })
}

const main = async () => {
  // await eonsVerify();
  // await eonsLpVerify();
  // await eEONSVerify();
  // await feeApproverVerify();
  // await wethGatewayAddressVerify();
  // await eonsQuickVaultVerify();
  // await eonsQuickRouterVerify();
  // await eonsAaveRouterVerify();
  await eonsAaveVaultVerify();
  // await eonsControllerVerify();
};

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
