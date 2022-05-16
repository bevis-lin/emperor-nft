require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  defaultNetwork: "hardhat",
  solidity: "0.8.1",
  networks: {
    hardhat: {},
    matic: {
      url: `${process.env.ALCHEMY_MATIC_URL}`,
      accounts: [`0x${process.env.MATIC_PRIVATE_KEY}`],
    },
  },
};
