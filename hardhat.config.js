require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'kovan',
  networks: {
    hardhat: {},
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: {mnemonic: 'solve glimpse eight match hold wreck school violin boost sight domain half'},
      live: true,
      saveDeployments: true
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: {mnemonic: process.env.MNEMONIC},
      live: true,
      saveDeployments: true
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: {mnemonic: process.env.MNEMONIC},
      live: true,
      saveDeployments: true
    },
    binanceTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: {mnemonic: process.env.MNEMONIC},
      live: true,
      saveDeployments: true
    },
    binanceMainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: {mnemonic: process.env.MNEMONIC},
      live: true,
      saveDeployments: true
    }
  },
  solidity: '0.7.3',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  etherscan: {
    // Ethereum
    apiKey: process.env.ETHERSCAN_API_KEY,

    // Binance
    // apiKey: process.env.BINANCE_ETHERSCAN_API_KEY
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts'
  },
  mocha: {
    timeout: 20000
  }
};
