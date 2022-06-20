const { ethers, waffle } = require("hardhat");
const hre = require("hardhat");
const USDC = require("./USDC.js");

async function main() {
  //provider and signers
  const provider = waffle.provider;
  const [deployer, testAcc] = await hre.ethers.getSigners();
  const usdcContract = await hre.ethers.getContractAt(
    USDC,
    "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E"
  );

  //deploying contract

  const StableHedge = await hre.ethers.getContractFactory("StableHedge");
  const stableHedge = await StableHedge.deploy();
  await stableHedge.deployed();

  console.log("Contract deployed to:", stableHedge.address);
  const amountIn = hre.ethers.utils.parseEther("1");
  const swapAvaxToJoe = await stableHedge.deposit(
    hre.ethers.utils.parseUnits("100", 6),
    [
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
    ],
    "1655957322",
    { value: hre.ethers.utils.parseEther("200") }
  );
  await swapAvaxToJoe.wait();

  const newBalance = await usdcContract.balanceOf(stableHedge.address);
  console.log(
    `new usdc balance of the contract: ${hre.ethers.utils
      .formatUnits(newBalance, 6)
      .toString()}`
  );
  const holding = await stableHedge.allHoldings(deployer.address);
  console.log(holding);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npm test => testing in avalanche mainnet via forking
