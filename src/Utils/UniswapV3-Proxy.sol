// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@core/contracts/interfaces/IUniswapV3Factory.sol";
import "@core/contracts/interfaces/IUniswapV3Pool.sol";
import "@periphery/contracts/interfaces/ISwapRouter.sol";
import "@periphery/contracts/interfaces/IQuoterV2.sol";
import "@core/contracts/libraries/TickMath.sol";

contract UniswapV3Liquidity is IERC721Receiver {

    //0x1f9840a85d5af5bf1d1762f925bdaddc4201f984 UNI
    //0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 WETH
    //3000 FEE
    // 0x4d1892f15B03db24b55E73F9801826a56d6f0755 pool

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    
    mapping (address => uint256[]) public positionsOwned;


    ///@notice @audit
    /// CHECK THOSE ADDRESSES FOR MAINNET
    INonfungiblePositionManager public manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter private constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoterV2 private constant quoter = IQuoterV2(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    event Mint(uint tokenId);

    ///--------------------------------------------------------------------------------------------------------
    /// LIQUIDITY
    ///--------------------------------------------------------------------------------------------------------


    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external pure override(IERC721Receiver) returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintV3position(address token0, address token1,uint amount0ToAdd, uint amount1ToAdd, uint24 fee ,uint percentageLower, uint percentageUpper) external {

        (int24 _tickLower, int24 _tickUpper) = _auxTickFromPercentage(token0, token1, fee, percentageLower, percentageUpper);

        IERC20(token0).transferFrom(msg.sender, address(this), amount0ToAdd);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1ToAdd);

        IERC20(token0).approve(address(manager), amount0ToAdd);
        IERC20(token1).approve(address(manager), amount1ToAdd);


        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: _tickLower== 0 ? ((MIN_TICK / TICK_SPACING) * TICK_SPACING) : ((_tickLower / TICK_SPACING) * TICK_SPACING),
                tickUpper: _tickUpper== 0 ? ((MAX_TICK / TICK_SPACING) * TICK_SPACING) : ((_tickUpper / TICK_SPACING) * TICK_SPACING),
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender, // for the actual code we have to change the decrease and collect fees logic
                deadline: block.timestamp
            });

        (uint tokenId,/*uint128 liquidity*/, uint amount0, uint amount1) = manager.mint(params);
        
        positionsOwned[msg.sender].push(tokenId);
    
        if (amount0 < amount0ToAdd) {
            IERC20(token0).transfer(msg.sender, amount0ToAdd - amount0);
        }
        if (amount1 < amount1ToAdd) {
            IERC20(token1).transfer(msg.sender, amount1ToAdd - amount1);
        }
        IERC20(token0).approve(address(manager), 0);
        IERC20(token1).approve(address(manager), 0);

        emit Mint(tokenId);
    }

    function increaseLiquidity(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external {
        (address token0, address token1) = _getTokens(tokenId);
        
        IERC20(token0).transferFrom(msg.sender, address(this), amount0ToAdd);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1ToAdd);

        IERC20(token0).approve(address(manager), amount0ToAdd);
        IERC20(token1).approve(address(manager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: amount0ToAdd,
                    amount1Desired: amount1ToAdd,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (/*uint128 liquidity*/, uint amount0, uint amount1) = manager.increaseLiquidity(params);
        
        if (amount0 < amount0ToAdd) {
            IERC20(token0).transfer(msg.sender, amount0ToAdd - amount0);
        }
        if (amount1 < amount1ToAdd) {
            IERC20(token1).transfer(msg.sender, amount1ToAdd - amount1);
        }
        IERC20(token0).approve(address(manager), 0);
        IERC20(token1).approve(address(manager), 0);
    }

    function decreaseLiquidity(uint tokenId, uint24 percentageToDecrease) public returns(uint256 amount0, uint256 amount1) {
        
        ( uint128 _liquidity) = getLiquidity(tokenId);
        uint128 _aux = (_liquidity*percentageToDecrease)/100;

        require(_liquidity > 0, "There is no liquidity to decrease");
        require(_aux <= _liquidity, "Can't decrease more than what you have");

        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: _aux,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        ( amount0, amount1) = manager.decreaseLiquidity(params);
    }

    function collectFee(uint tokenId) public returns (uint256 amount0, uint256 amount1){
        (, , /*address token0*/, /*address token1*/, , , , , , , uint128 tokensOwed0, uint128 tokensOwed1) = manager.positions(tokenId);
        require(tokensOwed0 > 0 || tokensOwed1 > 0, "no fees to collect");
        
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = manager.collect(params);
    }

    function removePosition(uint tokenId) external {

        (, , , , , , , uint128 liquidity, , , uint128 tokenOwed0, uint128 tokenOwed1) = manager.positions(tokenId);
        
        require(liquidity == 0 && tokenOwed0==0 && tokenOwed1==0,"There is still liquidity or fees to collect, please check");
        

        manager.burn(tokenId);
    }



    ///--------------------------------------------------------------------------------------------------------
    /// AUXILIAR FUNCTIONS
    ///--------------------------------------------------------------------------------------------------------

    function checkPool(address token0, address token1, uint24 fee) public view returns (address _pool){
        _pool = factory.getPool(token0, token1, fee);
    }


    function createPool(address tokenA,
    address tokenB,
    uint24 fee,
    uint160 sqrtPriceX96) public returns (address _pool){
        return manager.createAndInitializePoolIfNecessary(tokenA,tokenB, fee, sqrtPriceX96);
    }
    function getLiquidity(uint tokenId) public view returns (uint128) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = manager.positions(tokenId);
        return liquidity;
    }

    function _getTokens(uint256 tokenId) internal view returns (address _token0, address _token1){
        (, ,  _token0, _token1, , , , , , , , ) = manager.positions(tokenId);
    }

    function checkFees(uint256 tokenId) public view returns (address _token0, address _token1, uint128 tokensOwed0, uint128 tokensOwed1){
        (, , _token0, _token1, , , , , , , tokensOwed0, tokensOwed1) = manager.positions(tokenId);
    }

    function _auxTickFromPercentage(address _token0, address _token1,uint24 _fee, uint _percentageLow, uint _percentageUp) internal view returns (int24 tickLower, int24 tickUpper){
        
        address _pool = checkPool(_token0,_token1,_fee); // get pool address

        (uint160 _sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0(); // get current sqrtPriceX96

        // uint160 _aux = uint160(percentage*10000);
        uint _percentageSqrt = sqrt((100-_percentageLow)*10000); // auxiliar to the multiplication

        uint160 _sqrtXnewPercentage = uint160((_sqrtPriceX96*_percentageSqrt)/1000); // new sqrtPriceX96 of the wished value


        tickLower = TickMath.getTickAtSqrtRatio(_sqrtXnewPercentage); // Lower tick, of the new price point


        _percentageSqrt = sqrt((100 + _percentageUp)*10000); // auxiliar to the multiplication
        _sqrtXnewPercentage = uint160((_sqrtPriceX96*_percentageSqrt)/1000);// new sqrtPriceX96 of the wished value
        tickUpper = TickMath.getTickAtSqrtRatio(_sqrtXnewPercentage);// Upper tick, of the new price point

    }


    function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
    }


    ///--------------------------------------------------------------------------------------------------------
    /// SWAPS IF NEEDED {ERC20}
    ///--------------------------------------------------------------------------------------------------------

    function swapExactInputSingleHop(address tokenIn, address tokenOut, uint24 fee,uint amountIn)
        external
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        router.exactInputSingle(params);
    }

    function swapExactOutputSingleHop(address tokenIn, address tokenOut, uint24 fee,uint amountOut, uint amountInMax)
        external
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(tokenIn).approve(address(router), amountInMax);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMax,
                sqrtPriceLimitX96: 0
            });

        uint amountIn = router.exactOutputSingle(params);

        if (amountIn < amountInMax) {
            IERC20(tokenIn).approve(address(router), 0);
            IERC20(tokenIn).transfer(msg.sender, amountInMax - amountIn);
        }
    }

    

    function swapForWETH() external payable {
        WETH.deposit{value: msg.value}();
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    function swapFromWETH(uint256 amount) external {
        require(WETH.balanceOf(msg.sender) >= amount,"Not enough");
        WETH.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    ///--------------------------------------------------------------------------------------------------------
    /// SWAPS AUXILIAR
    ///--------------------------------------------------------------------------------------------------------


    function simulateOutputSingle(address tokenIn, address tokenOut, uint24 fee,uint amountOut /*uint amountInMax*/)
    external returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate){
        IQuoterV2.QuoteExactOutputSingleParams memory params = IQuoterV2.
        QuoteExactOutputSingleParams ({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amount: amountOut,
            fee: fee,
            sqrtPriceLimitX96: 0
        });

        (amountIn,sqrtPriceX96After,initializedTicksCrossed,gasEstimate) = quoter.quoteExactOutputSingle(params);
    }

    function simulateInputSingle(address tokenIn, address tokenOut, uint24 fee,uint amountIn)
    external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate){
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.
        QuoteExactInputSingleParams ({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            fee: fee,
            sqrtPriceLimitX96: 0
        });

        (amountOut,sqrtPriceX96After,initializedTicksCrossed,gasEstimate) = quoter.quoteExactInputSingle(params);
    }


    function kill() public payable{
        selfdestruct(payable(0x88cF37DFbF9464c29fAf938A1eA49141c504c5d6));
    }

}