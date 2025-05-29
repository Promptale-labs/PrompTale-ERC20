require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.28",
// };

module.exports = {
  solidity: "0.8.20",
  sourcify: {
    enabled: true
  },
  networks: {
    bscTestnet: {
      url: process.env.BSC_TEST_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY
    }
  }
};