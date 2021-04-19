require('dotenv').config();
const hre = require('hardhat');

const eonsAddress = '0x9f16b45D0B189764d90900Bd85DC668663C7d22E';

const eonsVerify = async () => {
  if (eonsAddress) {
    await hre.run('verify:verify', {
      network: 'binanceTestnet',
      address: eonsAddress
    })
  }
};

eonsVerify();
