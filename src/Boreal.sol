// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils/UniswapV3-Proxy.sol";
import "./Interfaces/ILido.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Boreal is UniswapV3Liquidity{

    //Ethereum : 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
    //Gorli : 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F
    ILido public lidoContract = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    //Ethereum : 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
    //Gorli : 0x6320cD32aA674d2898A68ec82e869385Fc5f7E2f
    address public wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address public wDREX;

    address public uniPool;

    address public multisig;
    

    constructor(uint160 _sqrtPricex96, address _multisig, address _wDREX){
        wDREX = _wDREX;
        address _pool = UniswapV3Liquidity.checkPool(wstETH, wDREX, 500);
        if (_pool == address(0)){
            // uniPool = UniswapV3Liquidity.createPool(wstETH, wDREX, 500, _sqrtPricex96);
        } else {
            uniPool = _pool;
        }

        multisig = _multisig;
    }


    function depositForStETH() external payable returns(uint256){
        uint256 _amount = lidoContract.submit{value: msg.value}(multisig);

        lidoContract.transferShares(msg.sender, _amount);
    }
    function depositForWstETH() external payable {
        (bool _success,bytes memory _bytes) = wstETH.call{value:msg.value}("");

        require(_success);

        IERC20(wstETH).transfer(msg.sender, _bytesToUint(_bytes));
    }


    function _bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

}