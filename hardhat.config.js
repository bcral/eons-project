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
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        enabled: true,
        url: "https://eth-mainnet.alchemyapi.io/v2/${process.env.alchemyKey}",
        blockNumber: 13241496,
      },
    },
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // },
    // kovan: {
    //   url: `https://kovan.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // },
    // mainnet: {
    //   url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // },
    // binanceTestnet: {
    //   url: "https://data-seed-prebsc-1-s1.binance.org:8545",
    //   chainId: 97,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // },
    // binanceMainnet: {
    //   url: "https://bsc-dataseed.binance.org/",
    //   chainId: 56,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // },
    // maticMainnet: {
    //   url: "https://polygon-rpc.com/",
    //   chainId: 137,
    //   accounts: [process.env.PRIVATE_KEY],
    //   live: true,
    //   saveDeployments: true
    // }
  },
  solidity: '0.8.4',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  etherscan: {
    // Ethereum
    // apiKey: process.env.ETHERSCAN_API_KEY,

    // Binance
    // apiKey: process.env.BINANCE_ETHERSCAN_API_KEY

    // Polygon
    // apiKey: process.env.POLYGONSCAN_API_KEY
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
