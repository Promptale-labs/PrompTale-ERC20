require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const Contract = await ethers.getContractFactory("TaleVestingWalletFactory");
  const contract = await Contract.deploy("0x789D37933044f7DBa49a4e3Dc5e9068590B70EE3");
  await contract.waitForDeployment();

  console.log("Token deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
