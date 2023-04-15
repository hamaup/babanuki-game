require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

const privateKey = "56861a5099729a231ea32bcd60e76aacd7de6052e0ecbc4f0e1e7fdf661a1c79"; // あなたの秘密鍵を入力

module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Adjust this value for better optimization
      },
    },
  },
  defaultNetwork: "localhost",
  networks: {
    hardhat: {},
    sandverse: {
      url: "https://rpc.sandverse.oasys.games/",
      chainId: 20197,
      accounts: [privateKey],
      gas: 0, // ガスリミットを適切に設定
      gasPrice: 0, // ガス価格を適切に設定
    },
    localhost: {
      url: "http://localhost:8545",
    },
  },

};