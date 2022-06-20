const { ethers, waffle } = require("hardhat");
const hre = require("hardhat");

async function main() {
  //provider and signers
  const provider = waffle.provider;
  const [deployer, testAcc] = await hre.ethers.getSigners();

  //deploying contract
  const StableHedge = await hre.ethers.getContractFactory("StableHedge");
  const stableHedge = await StableHedge.deploy();
  await stableHedge.deployed();

  console.log("Contract deployed to:", stableHedge.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npm test => testing in avalanche mainnet via forking
