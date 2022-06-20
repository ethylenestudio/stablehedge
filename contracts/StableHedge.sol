//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IJOERouter.sol";

//joe router contract: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
//wavax address: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
//usdc address: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E

error StableHedge__WrongPath(address requested, address correctAddress);

contract StableHedge {
    uint256 constant USDC_RATIO = 60; // dont forget to change
    uint256 constant USDTE_RATIO = 40;
    address constant USDC_ADDRESS = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; //will be given as constructor param in the prod
    address constant WAVAX_ADDRESS = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //will be given as constructor param in the prod
    IJOERouter immutable router;

    mapping(address => Holding) public allHoldings;

    struct Holding {
        uint USDCHold;
        uint USDTHold;
    }

    constructor() {
        router = IJOERouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); //will be given as constructor param in the prod
    }

    function deposit(
        uint usdcOutMin,
        address[] calldata USDCPath,
        uint deadline
    ) public payable returns (uint[] memory) {
        require(msg.value > 0, "You can't deposit 0");
        uint[] memory amounts = swapAvaxToStable(
            usdcOutMin,
            USDCPath,
            address(this),
            deadline
        );
        uint amountOfUSDC = amounts[amounts.length - 1];
        uint newUSDCHold = allHoldings[msg.sender].USDCHold + amountOfUSDC;
        allHoldings[msg.sender] = Holding(newUSDCHold, 0); //usdt is considered to be 0. reward and balance can be added to this struct
        return amounts;
    }

    function swapAvaxToStable(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) private returns (uint[] memory) {
        if (path[0] != WAVAX_ADDRESS) {
            revert StableHedge__WrongPath(path[0], WAVAX_ADDRESS);
        } else if (path[path.length - 1] != USDC_ADDRESS) {
            revert StableHedge__WrongPath(path[path.length - 1], USDC_ADDRESS);
        }
        uint[] memory amounts = router.swapExactAVAXForTokens{value: msg.value}( //SENDING ALL VALUE ATM
            amountOutMin,
            path,
            to,
            deadline
        );
        return amounts;
    }
}
