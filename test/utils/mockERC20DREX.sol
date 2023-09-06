//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mockERC20 is ERC20 {
    constructor() ERC20("wDREX","wDREX"){
        _mint(msg.sender, 10 ether);
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}