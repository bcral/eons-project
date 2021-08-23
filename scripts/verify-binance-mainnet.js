require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0x92019247d2F7D45EB675947195f4b30319d14318';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'binanceMainnet',
      address: eonsAddress
    })
  }
};

eonsVerify();
