const { ethers, waffle } = require("hardhat");
const hre = require("hardhat");
const stableAbi = require("./stableABI.js");

//npm test => testing in avalanche mainnet via forking

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
    "0xc7198437980c041c805A1EDcbA50c1Ce5db95118"
  );

  //deploying contract

  const StableHedge = await hre.ethers.getContractFactory("StableHedge");
  const stableHedge = await StableHedge.deploy();
  await stableHedge.deployed();

  console.log("Contract deployed to:", stableHedge.address);

  //DEPOSIT FUNCTIONS BITCHES
  await depositFunc(stableHedge, "1", "3");
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
  await stableHedge
    .allHoldings(deployer.address)
    .then((resp) => console.log("first deposit: ", resp));

  //deposit and check balance again.
  await depositFunc(stableHedge, "1", "1");

  await stableHedge
    .allHoldings(deployer.address)
    .then((resp) => console.log("second deposit: ", resp));

  const claimAave = await stableHedge.claimAaveRewards();
  await claimAave.wait();
  await provider
    .getBalance(stableHedge.address)
    .then((resp) => console.log(resp));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//deposit function
const depositFunc = async (contract, amountMin, depositAmount) => {
  const txn = await contract.deposit(
    hre.ethers.utils.parseUnits(amountMin, 6),
    hre.ethers.utils.parseUnits(amountMin, 6),
    [
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
    ],
    [
      "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7",
      "0xc7198437980c041c805A1EDcbA50c1Ce5db95118",
    ],
    "2655957322",
    { value: hre.ethers.utils.parseEther(depositAmount) }
  );
  await txn.wait();
};
