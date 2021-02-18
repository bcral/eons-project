require('@nomiclabs/hardhat-waffle');
require("@nomiclabs/hardhat-etherscan");

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
  defaultNetwork: 'rinkeby',
  networks: {
    hardhat: {},
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/53762114270846ca8f1a1a278cdf0b9a',
      accounts: {mnemonic: 'solve glimpse eight match hold wreck school violin boost sight domain half'},
      live: true,
      saveDeployments: true
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/53762114270846ca8f1a1a278cdf0b9a',
      accounts: {mnemonic: 'solve glimpse eight match hold wreck school violin boost sight domain half'},
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
    apiKey: 'CMNMRMTGRCVEWZ8GZMTXCDB1MXMHBS8S88'
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
