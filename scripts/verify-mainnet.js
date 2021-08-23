require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0xEf538B1604B0CcC265a99B295F2FeD4AD9dCddCf';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'mainnet',
      address: eonsAddress
    })
  }
};

eonsVerify();
