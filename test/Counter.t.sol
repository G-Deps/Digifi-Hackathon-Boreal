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
    IwithdrawalQueue public withdrawalQueue = IwithdrawalQueue(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);
    
    uint256[] public _amounts;
    function setUp() public {
        // vm.prank(main);

        mainnetFork = vm.createFork("https://mainnet.infura.io/v3/318cbfb64cdb4ff196531f4c9ba6b399");
        
    }

    function test_setup() public{
        vm.selectFork(mainnetFork);

        vm.startPrank(main);

        wDrex = new mockERC20();

        vm.deal(main, 10 ether);
        boreal = new Boreal(uint160(3924), address(0), address(wDrex));

        vm.stopPrank();
    }

    function teststETH() public {
        test_setup();
        vm.prank(main);
        console.log("Depositing 1 ether and getting stETH: ");
        boreal.depositForStETH{value: 1 ether}();
        console.log("Main stETH after: ", IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84).balanceOf(main));
    }
    function testwstETH() public {
        test_setup();
        console.log("Depositing 1 ether and getting wstETH: ");
        vm.prank(main);
        boreal.depositForWstETH{value: 1 ether}();
        console.log("Main wstETH after: ", IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0).balanceOf(main));
    }

    function testStakeUnstake() public {
        test_setup();

        vm.startPrank(main);
        console.log("Depositing 1 ether and getting stETH: ");

        uint256 _shares = boreal.depositForStETH{value: 1 ether}();
        uint256 _amount = lidoContract.getPooledEthByShares(_shares);
        

        console.log("Withdrawing 1 ether and getting the withdraw NFT: ");
        lidoContract.approve(address(boreal), _amount);
        _amounts.push(_amount);
        uint256 _requestId = boreal.queueSingleWithdraw(_amounts);

        console.log("Minted ID: ", _requestId);
        console.log("Owner Of minted ID: ", withdrawalQueue.ownerOf(_requestId));
    }
}
