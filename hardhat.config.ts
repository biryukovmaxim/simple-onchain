import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    arbitrum_goerli: {
      url: "https://endpoints.omniatech.io/v1/arbitrum/goerli/public",
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 421613,
    },
    arbitrum_one: {
      url: "https://endpoints.omniatech.io/v1/arbitrum/one/public",
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 42161,
    }
  },
  defaultNetwork: "arbitrum_goerli",
};

export default config;
