require('dotenv').config();
const hre = require('hardhat');

const addressToVerify = '0xf2a10621157f543b9bd9707c0213faa703dfb4e4';

const eonsVerify = async () => {
  if (addressToVerify) {
    await hre.run('verify:verify', {
      network: 'kovan',
      address: addressToVerify
    })
  }
};

eonsVerify();
