require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0x5c839ab2C421f781173c477a062713232524B4FA';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'kovan',
      address: eonsAddress
    })
  }
};

eonsVerify();
