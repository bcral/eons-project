require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0x574FB9aDc02E09AAC6c2AE0E05fD367F7E3Ec936';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'mainnet',
      address: eonsAddress
    })
  }
};

eonsVerify();
