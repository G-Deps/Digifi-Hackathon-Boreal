// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Boreal.sol";

contract DeployScript is Script {

    Boreal public boreal;
    uint256 _price = 8130*(10**12);
    address _multisig = 0xAaa7cCF1627aFDeddcDc2093f078C3F173C46cA4;
    address _wDREX = 0x438db7329230cCACBb5C02ee5b01b300eb13C633;
    function setUp() public {
    }

    function run() public {

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        boreal = new Boreal(_price, _multisig, _wDREX);

        console.log("Boreal Contract at : ",address(boreal));
        
        vm.stopBroadcast();
    }
}