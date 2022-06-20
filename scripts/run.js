const { ethers, waffle } = require("hardhat");
const hre = require("hardhat");
const stableAbi = require("./stableABI.js");

async function main() {
  //provider and signers
  const provider = waffle.provider;
  const [deployer, testAcc] = await hre.ethers.getSigners();
  const usdcContract = await hre.ethers.getContractAt(
    stableAbi,
    "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E"
  );
  const usdtContract = await hre.ethers.getContractAt(
    stableAbi,
    "0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7"
  );

  //deploying contract

  const StableHedge = await hre.ethers.getContractFactory("StableHedge");
  const stableHedge = await StableHedge.deploy();
  await stableHedge.deployed();

  console.log("Contract deployed to:", stableHedge.address);

  //DEPOSIT FUNCTIONS BITCHES
  const depositFunc = await stableHedge.deposit(
    hre.ethers.utils.parseUnits("1", 6),
    hre.ethers.utils.parseUnits("1", 6),
    [
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
    ],
    [
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7",
    ],
    "2655957322",
    { value: hre.ethers.utils.parseEther("2") }
  );
  await depositFunc.wait();

  //CONTRACTS BALANCE
  const newUSDCBalance = await usdcContract.balanceOf(stableHedge.address);
  const newUSDTBalance = await usdtContract.balanceOf(stableHedge.address);
  console.log(
    `new usdc balance of the contract: ${hre.ethers.utils
      .formatUnits(newUSDCBalance, 6)
      .toString()}`
  );
  console.log(
    `new usdt balance of the contract: ${hre.ethers.utils
      .formatUnits(newUSDTBalance, 6)
      .toString()}`
  );

  //USERS BALANCE BEING KEPT BY CONTRACT IN A MAPPING
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
