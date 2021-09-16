require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0xEf538B1604B0CcC265a99B295F2FeD4AD9dCddCf';
const eEONSAddress = '0x82D28bc61cbC7FBBe66b43B34938d1a345A459cf';

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

const main = async () => {
  // await eonsVerify();
  await eEONSVerify();
};

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });