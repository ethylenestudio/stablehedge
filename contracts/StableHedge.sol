//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IJOERouter.sol";

//joe router contract: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4

error StableHedge__WrongPath(address requested, address correctAddress);

contract StableHedge {
    //constants integers ***dont forget to change!!!
    uint256 constant USDC_RATIO = 60;
    uint256 constant USDT_RATIO = 40;

    //constant addresses
    address public constant USDC_ADDRESS =
        0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant USDT_ADDRESS =
        0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public constant WAVAX_ADDRESS =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    //immutable variables
    IJOERouter immutable router;

    //mapping and structs
    mapping(address => Holding) public allHoldings;

    struct Holding {
        uint256 USDCHold;
        uint256 USDTHold;
    }

    //@dev router address can be given in the parameter
    constructor() {
        router = IJOERouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    }

    function deposit(
        uint256 usdcOutMin,
        uint256 usdtOutMin,
        address[] calldata USDCPath,
        address[] calldata USDTPath,
        uint256 deadline
    ) public payable {
        require(msg.value > 0, "You can't deposit 0");

        if (USDCPath[USDCPath.length - 1] != USDC_ADDRESS) {
            revert StableHedge__WrongPath(
                USDCPath[USDCPath.length - 1],
                USDC_ADDRESS
            );
        }
        if (USDTPath[USDTPath.length - 1] != USDT_ADDRESS) {
            revert StableHedge__WrongPath(
                USDTPath[USDCPath.length - 1],
                USDT_ADDRESS
            );
        }

        uint256[] memory USDCAmount = swapAvaxToStable(
            usdcOutMin,
            USDCPath,
            address(this),
            deadline,
            USDC_RATIO
        );
        uint256[] memory USDTAmount = swapAvaxToStable(
            usdtOutMin,
            USDTPath,
            address(this),
            deadline,
            USDT_RATIO
        );
        uint256 newUSDCHold = allHoldings[msg.sender].USDCHold +
            USDCAmount[USDCAmount.length - 1];
        uint256 newUSDTHold = allHoldings[msg.sender].USDTHold +
            USDTAmount[USDTAmount.length - 1];
        allHoldings[msg.sender] = Holding(newUSDCHold, newUSDTHold);
    }

    function swapAvaxToStable(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 ratio
    ) private returns (uint[] memory) {
        if (path[0] != WAVAX_ADDRESS) {
            revert StableHedge__WrongPath(path[0], WAVAX_ADDRESS);
        }
        uint[] memory amounts = router.swapExactAVAXForTokens{
            value: (msg.value * ratio) / 100
        }(amountOutMin, path, to, deadline);
        return amounts;
    }
}
