require('dotenv').config();
const hre = require('hardhat');

const addressToVerify = '0xdb0f94c2d5aff0b6afb2adf3693dcc0ce40f24da';
const feeAddress = '0xEc065c6092ec8d1af0eCeFFb021e138ab9bfC907';

const eonsVerify = async () => {
  if (addressToVerify) {
    await hre.run('verify:verify', {
      network: 'kovan',
      address: addressToVerify
    })
  }
};

const feeVerify = async () => {
  if (feeAddress) {
    await hre.run('verify:verify', {
      network: 'kovan',
      address: addressToVerify,
      constructorArguments: [
        '0x544ff9722dFD5D5ed04D78a8764f057ad3303D90',
        '0xd0a1e359811322d97991e03f863a0c30c2cf029c',
        '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f'
      ]
    })
  }
};

eonsVerify();
// feeVerify();