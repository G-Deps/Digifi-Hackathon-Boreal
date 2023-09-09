// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils/UniswapV3-Proxy.sol";
import "./Interfaces/ILido.sol";
import "./Interfaces/IwstETH.sol";
import "./Interfaces/IwithdrawalQueue.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Boreal is UniswapV3Liquidity, Ownable{

    //Ethereum : 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
    //Gorli : 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F
    ILido public lidoContract = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    //Ethereum : 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
    //Gorli : 0x6320cD32aA674d2898A68ec82e869385Fc5f7E2f
    IwstETH public wstETH = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    //Ethereum : 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1
    //Gorli : 0xCF117961421cA9e546cD7f50bC73abCdB3039533
    IwithdrawalQueue public withdrawalQueue = IwithdrawalQueue(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

    address public wDREX;

    address public uniPool;

    address public multisig;
    
    mapping (uint256 => uint256) public requests;

    //price sqrt(token1/token0) Q64.96
    constructor(uint256 _price, address _multisig, address _wDREX)Ownable(){
        wDREX = _wDREX;

        uint160 _sqrtPricex96 = uint160(sqrt(_price)*(2**96));
        address _pool = UniswapV3Liquidity.checkPool(wDREX, address(wstETH), 500);
        if (_pool == address(0)){
            uniPool = UniswapV3Liquidity.createPool(wDREX, address(wstETH), 500, _sqrtPricex96);
        } else {
            uniPool = _pool;
        }

        multisig = _multisig;
    }

    receive() external payable {}


    function depositForStETH() external payable returns(uint256 _amount){
        _amount = lidoContract.submit{value: msg.value}(multisig);

        require(lidoContract.transferShares(msg.sender, _amount) > 0,"Boreal : Shares transfer failed");
    }
    function depositForWstETH() external payable {
        uint256 _shares = lidoContract.submit{value: msg.value}(multisig);
        uint256 _stETH = lidoContract.getPooledEthByShares(_shares);

        lidoContract.approve(address(wstETH), _stETH);

        uint _wstETH = wstETH.wrap(_stETH);

        require(wstETH.transfer(msg.sender, _wstETH), "Boreal : wstETH transfer failed");
    }

    function wrapStETH(uint256 _amount) external {
        require(lidoContract.allowance(msg.sender, address(this)) >= _amount,"Boreal : Not enough allowance");
        require(lidoContract.transferFrom(msg.sender, address(this), _amount),"Boreal : stETH transfer failed from the allowance");
        lidoContract.approve(address(wstETH),_amount);
        uint _wstETH = wstETH.wrap(_amount);

        require(wstETH.transfer(msg.sender, _wstETH),"Boreal : wstETH transfer failed on wrap");

    }

    function unwrapWstETH(uint256 _amount) external {
        require(wstETH.allowance(msg.sender, address(this)) >= _amount, "Boreal, Not enough allowance");

        require(wstETH.transferFrom(msg.sender, address(this), _amount), "Boreal : wstETH transfer failed from the allowance");

        wstETH.approve(address(wstETH), _amount);
        uint256 _stETH = wstETH.unwrap(_amount);

        require(lidoContract.transfer(msg.sender, _stETH),"Boreal : stETH transfer failed");
    }


    function queueSingleWithdraw(uint256[] calldata _amounts) external returns(uint256 _requestID){
        require(_amounts.length == 1, "Boreal : Can only require one withdraw");
        require(lidoContract.allowance(msg.sender, address(this)) >= _amounts[0], "Boreal : You have to approve the amount");
        require(lidoContract.transferFrom(msg.sender, address(this), _amounts[0]),"Boreal : Transfer of stETH from msg.sender failed");
        //uint256[] calldata _amounts, address _owner
        lidoContract.approve(address(withdrawalQueue), _amounts[0]);
        _requestID = withdrawalQueue.requestWithdrawals(_amounts, address(0))[0];
        requests[_requestID] = _amounts[0];
        withdrawalQueue.transferFrom(address(this), msg.sender, _requestID);
    }

    function executeWithdraw(uint256 _requestID) external {
        require(requests[_requestID] > 0, "Boreal : Either not requested here or already claimed");
        address owner = withdrawalQueue.ownerOf(_requestID);
        require(owner == msg.sender, "Boreal : Only the withdrawal request owner can withdraw");
        require(withdrawalQueue.getApproved(_requestID) == address(this), "Boreal : You have to approve this address");

        withdrawalQueue.transferFrom(msg.sender, address(this), _requestID);
        withdrawalQueue.claimWithdrawal(_requestID);

        (bool _success, ) = payable(msg.sender).call{value : requests[_requestID]}("");

        require(_success, "Boreal : Not able to receive the ether");
    }


    function _bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function getSlot0() external view returns(uint160 _sqrtPriceX96){
        (_sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniPool).slot0();
    }


    function changeDrex(address _wdrex) onlyOwner {
        wDREX = _wdrex;
    }

    function changeMultisig(address _multisig) onlyOwner {
        multisig = _multisig;
    }

    function kill() onlyOwner {
        selfdestruct(payable(msg.sender));
    }


}