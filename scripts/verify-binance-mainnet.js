require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'binanceMainnet',
      address: eonsAddress
    })
  }
};

eonsVerify();
