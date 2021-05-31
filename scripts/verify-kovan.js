require('dotenv').config();
const hre = require('hardhat');

const addressToVerify = '0x265f4eaa36afbd100136dbb1b9dd1b7712d34075';

const eonsVerify = async () => {
  if (addressToVerify) {
    await hre.run('verify:verify', {
      network: 'kovan',
      address: addressToVerify
    })
  }
};

eonsVerify();
