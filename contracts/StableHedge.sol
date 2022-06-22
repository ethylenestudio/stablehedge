//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IJOERouter.sol";
import "./interfaces/IPoolAave.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPoolPlatypus.sol";
import "./interfaces/IStakePlatypus.sol";

//joe router contract: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4

//ulaş bunları require'a çevirme nolur
error StableHedge__WrongPath(address[] wrongPath);
error StableHedge__NotEnoughBalance();

contract StableHedge {
    //constants integers ***dont forget to change!!!
    uint256 constant USDC_RATIO = 60;

    //constant addresses
    address public constant USDC_ADDRESS =
        0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant USDT_ADDRESS =
        0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    //immutable variables
    IJOERouter immutable router;
    IPoolAave immutable aave;
    IPoolPlatypus immutable ptp;
    IStakePlatypus immutable ptpStake;
    IERC20 immutable usdcContract;
    IERC20 immutable usdtContract;
    IERC20 immutable ptpUsdtLPContract;

    //mapping,variables and structs
    mapping(address => Holding) public allHoldings;
    uint256 public USDC_Balance;
    uint256 public USDT_Balance;
    uint256 UndistributedReward;

    struct Holding {
        uint256 USDCHold;
        uint256 USDTHold;
        uint256 USDTLPAmount;
    }

    //@dev router address can be given in the parameter
    constructor() {
        router = IJOERouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        aave = IPoolAave(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
        ptp = IPoolPlatypus(0x66357dCaCe80431aee0A7507e2E361B7e2402370);
        ptpStake = IStakePlatypus(0x68c5f4374228BEEdFa078e77b5ed93C28a2f713E);
        usdcContract = IERC20(USDC_ADDRESS);
        usdtContract = IERC20(USDT_ADDRESS);
        ptpUsdtLPContract = IERC20(0x0D26D103c91F63052Fbca88aAF01d5304Ae40015);
    }

    receive() external payable {}

    fallback() external payable {}

    //DEPOSIT TO PLATFORM

    function deposit(
        uint256 usdcOutMin,
        uint256 usdtOutMin,
        address[] calldata USDCPath,
        address[] calldata USDTPath,
        uint256 deadline
    ) public payable {
        require(msg.value > 0, "You can't deposit 0");

        if (
            USDCPath[0] != router.WAVAX() ||
            USDCPath[USDCPath.length - 1] != USDC_ADDRESS
        ) {
            revert StableHedge__WrongPath(USDCPath);
        }

        if (
            USDTPath[0] != router.WAVAX() ||
            USDTPath[USDTPath.length - 1] != USDT_ADDRESS
        ) {
            revert StableHedge__WrongPath(USDTPath);
        }

        uint256[] memory USDCAmount = swapAvaxToStable(
            usdcOutMin,
            USDCPath,
            address(this),
            deadline,
            ((msg.value * USDC_RATIO) / 100)
        );

        uint256[] memory USDTAmount = swapAvaxToStable(
            usdtOutMin,
            USDTPath,
            address(this),
            deadline,
            (msg.value - ((msg.value * USDC_RATIO) / 100))
        );

        depositToAave(USDC_ADDRESS, USDCAmount[USDCAmount.length - 1]);
        depositToPtp(USDTAmount[USDTAmount.length - 1], deadline);

        USDC_Balance += USDCAmount[USDCAmount.length - 1];
        allHoldings[msg.sender].USDCHold += USDCAmount[USDCAmount.length - 1];

        USDT_Balance += USDTAmount[USDTAmount.length - 1];
        allHoldings[msg.sender].USDTHold += USDTAmount[USDTAmount.length - 1];
    }

    //SWAP FUNCTIONS

    function swapAvaxToStable(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 ratio
    ) private returns (uint256[] memory) {
        if (path[0] != router.WAVAX()) {
            revert StableHedge__WrongPath(path);
        }
        uint256[] memory amounts = router.swapExactAVAXForTokens{value: ratio}(
            amountOutMin,
            path,
            to,
            deadline
        );
        return amounts;
    }

    //DEPOSIT TO STRATEGIES

    function depositToAave(address asset, uint256 amount) private {
        usdcContract.approve(
            0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            amount
        );
        aave.supply(asset, amount, address(this), 0);
    }

    function depositToPtp(uint256 amount, uint256 deadline)
        private
        returns (uint256)
    {
        allHoldings[msg.sender].USDTHold = 0;
        usdtContract.approve(
            0x66357dCaCe80431aee0A7507e2E361B7e2402370,
            amount
        );
        ptpUsdtLPContract.approve(
            0x68c5f4374228BEEdFa078e77b5ed93C28a2f713E,
            amount
        );
        uint256 liquidity = ptp.deposit(
            USDT_ADDRESS,
            amount,
            address(this),
            deadline
        );
        ptpStake.deposit(0, liquidity);
        allHoldings[msg.sender].USDTLPAmount += liquidity;
        return liquidity;
    }

    //CLAIM REWARDS



    //WITHDRAW

    function withdrawFromPtp(uint256 deadline) public {
        if (allHoldings[msg.sender].USDTLPAmount == 0) {
            revert StableHedge__NotEnoughBalance();
        }
        allHoldings[msg.sender].USDTLPAmount = 0;
        uint256 amount = ptp.withdraw(
            USDT_ADDRESS,
            allHoldings[msg.sender].USDTLPAmount,
            (allHoldings[msg.sender].USDTLPAmount * 998) / 1000,
            address(this),
            deadline
        );
        allHoldings[msg.sender].USDTHold += amount;
    }
}
