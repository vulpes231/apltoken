require("@nomicfoundation/hardhat-toolbox");
// require("./tasks");
require("dotenv").config();

const COMPILER_SETTINGS = {
  optimizer: {
    enabled: true,
    runs: 1000000,
  },
  metadata: {
    bytecodeHash: "none",
  },
};

const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL ||
  process.env.ALCHEMY_MAINNET_RPC_URL ||
  "https://eth-mainnet.alchemyapi.io/v2/your-api-key";

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;

const SUPER_SMART_CHAIN_URL = process.env.SUPER_SMART_CHAIN_TESTNET_RPC_URL;

const PRIVATE_KEY = process.env.TSCS_PRIVATE_KEY;

// Your API key for Etherscan, obtain one at https://etherscan.io/
const ETHERSCAN_API_KEY =
  process.env.ETHERSCAN_API_KEY || "Your etherscan API key";

const REPORT_GAS = process.env.REPORT_GAS || false;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        COMPILER_SETTINGS,
      },
    ],
  },
  networks: {
    localhost: {
      chainId: 31337,
    },
    tscs: {
      url: SUPER_SMART_CHAIN_URL !== undefined ? SUPER_SMART_CHAIN_URL : "",
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      chainId: 1969,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL !== undefined ? SEPOLIA_RPC_URL : "",
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      chainId: 11155111,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      chainId: 1,
    },
  },
  defaultNetwork: "hardhat",
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    apiKey: {
      // npx hardhat verify --list-networks
      sepolia: ETHERSCAN_API_KEY,
      mainnet: ETHERSCAN_API_KEY,
    },
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  contractSizer: {
    runOnCompile: false,
    only: [
      "APIConsumer",
      "AutomationCounter",
      "NFTFloorPriceConsumerV3",
      "PriceConsumerV3",
      "RandomNumberConsumerV2",
      "RandomNumberDirectFundingConsumerV2",
    ],
  },
  // paths: {
  //   sources: "./contracts",
  //   tests: "./test",
  //   cache: "./build/cache",
  //   artifacts: "./build/artifacts",
  // },
  mocha: {
    timeout: 300000, // 300 seconds max for running tests
  },
};
