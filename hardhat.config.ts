// eslint-disable-next-line import/no-extraneous-dependencies
import '@nomiclabs/hardhat-waffle';
import 'solidity-coverage';

export default {
  solidity: {
    version: '0.8.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: 'https://api.avax.network/ext/bc/C/rpc',
      },
      mining: {
        auto: true,
        interval: 5000,
      },
    },
  },

  mocha: {
    timeout: 4000000,
  },
};
