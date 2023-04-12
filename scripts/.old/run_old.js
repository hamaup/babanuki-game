const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const BabanukiNFT = await hre.ethers.getContractFactory("BabanukiNFT");
  const babanukiNFT = await BabanukiNFT.deploy();

  await babanukiNFT.deployed();

  console.log("BabanukiNFT deployed to:", babanukiNFT.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
