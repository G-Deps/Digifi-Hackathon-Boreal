// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Boreal.sol";
import "./utils/mockERC20DREX.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BorealTest is Test {
    uint256 public mainnetFork;
    Boreal public boreal;

    mockERC20 public wDrex;

    address public main = makeAddr("main");

    ILido public lidoContract = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    
    function setUp() public {
        // vm.prank(main);

        mainnetFork = vm.createFork("https://mainnet.infura.io/v3/318cbfb64cdb4ff196531f4c9ba6b399");
    }

    function teststETH() public {
        vm.selectFork(mainnetFork);

        vm.startPrank(main);

        wDrex = new mockERC20();

        vm.deal(main, 10 ether);
        boreal = new Boreal(uint160(3924), address(0), address(wDrex));
        uint256 amount = boreal.depositForStETH{value: 1 ether}();
        vm.stopPrank();
        console.log("Main stETH after: ", IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84).balanceOf(main));
    }
    function testwstETH() public {
        vm.selectFork(mainnetFork);

        vm.startPrank(main);

        wDrex = new mockERC20();

        vm.deal(main, 10 ether);
        boreal = new Boreal(uint160(3924), address(0), address(wDrex));
        boreal.depositForWstETH{value: 1 ether}();
        vm.stopPrank();
        console.log("Main wstETH after: ", IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0).balanceOf(main));
        console.log("Boreal wstETH after: ", IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0).balanceOf(address(boreal)));
    }
}
