// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;


interface IUniswapV3Liquidity {

    //IWETH ADDRESSES
    // Ethereum	1	WETH	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Ropsten	3	WETH	0xc778417E063141139Fce010982780140Aa0cD5Ab
    // Rinkeby	4	WETH	0xc778417E063141139Fce010982780140Aa0cD5Ab
    // Goerli	5	WETH	0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    // Kovan	42	WETH	0xd0A1E359811322d97991E03f863a0C30C2cF029C
    // Optimism	10	WETH	0x4200000000000000000000000000000000000006
    // Optimistic Kovan	69	WETH	0x4200000000000000000000000000000000000006
    // Arbitrum One	42161	WETH	0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    // Arbitrum Rinkeby	421611	WETH	0xB47e6A5f8b33b3F17603C83a0535A9dcD7E32681
    // Polygon	137	WMATIC	0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    // Polygon Mumbai	80001	WMATIC	0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889

    // USE FUNCTION DEPOSIT TO SEND NATIVE TOKEN AND RECEIVE THE WRAPPED TOKEN

    // DEPLOYED CONTRACT IN POLYGON https://polygonscan.com/address/0x7E2a3A21efd2E0f4Afa2713ddecA0ec2c1Ab3B82


    ///--------------------------------------------------------------------------------------------------------
    /// LIQUIDITY
    ///--------------------------------------------------------------------------------------------------------

    ///@dev Function to mint a new uniswap V3 position based on tick
    ///@param token0 is the address of the first token of the pair
    ///@param token1 is the address of the second token of the pair
    ///@param amount0ToAdd is the amount of the first token to add {WITH ALL DECIMALS} {you have to approve the contract to move those amounts like ERC20.approve("address contract", amount0ToAdd)}
    ///@param amount1ToAdd is the amount of the second token to add {WITH ALL DECIMALS} {you have to approve the contract to move those amounts like ERC20.approve("address contract", amount1ToAdd)}
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param percentageLower is the percentage that you want to place your lower tick based on the current price {input like 0 - 100} {like currentPrice - 30%}
    ///@param percentageUpper is the percentage that you want to place your upper tick based on the current price {input like 0 - 100} {like currentPrice + 30%}
    function mintV3position(address token0, address token1,uint amount0ToAdd, uint amount1ToAdd, uint24 fee ,uint percentageLower, uint percentageUpper) external;


    ///@dev Function to increase the liquidity of the position
    ///@param tokenId is the tokenId of the minted V3 position
    ///@param amount0ToAdd is the amount of the first token to add {you have to approve the contract to move those amounts like ERC20.approve("address contract", amount0ToAdd)}
    ///@param amount1ToAdd is the amount of the second token to add {you have to approve the contract to move those amounts like ERC20.approve("address contract", amount1ToAdd)}
    function increaseLiquidity(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external;

    ///@dev Functions to decrease liquidity
    ///@param tokenId is the tokenId of the minted V3 position
    ///@param percentageToDecrease is the % of the amount to be decrease in the range of {0 - 100} WITHOUT DECIMAL POINT
    ///@notice in order for this function to work the user have to approve the proxy contract to move their NFT, with the function {ERC721.approve("address of the contract", tokenId)} on the front-end
    function decreaseLiquidity(uint tokenId, uint24 percentageToDecrease) external;

    ///@dev Function to collect the available fees
    ///@param tokenId is the tokenId of the minted V3 position
    function collectFee(uint tokenId) external;

    ///@dev Function to remove liquidity, collect fees and burn NFT
    ///@param tokenId is the tokenId of the minted V3 position 
    ///@notice DO NOT USE, THIS FUNCTION IS NOT FINISHED YET {IT IS NOT WORKING PROPERLY}
    function removePosition(uint tokenId) external;


    ///--------------------------------------------------------------------------------------------------------
    /// AUXILIAR FUNCTIONS
    ///--------------------------------------------------------------------------------------------------------

    ///@dev Function to return the pool address if exists
    ///@param token0 is the first token address of the pair
    ///@param token1 is the second token address of the pair
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param _pool is the address of the pair pool
    function checkPool(address token0, address token1, uint24 fee) external view returns (address _pool);

    ///@dev Function to create a pool if needed
    ///@param tokenA is the first token address of the pair
    ///@param tokenB is the second token address of the pair
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param sqrtPriceX96 is the value from the following equation {sqrt(price) * pow(2,96)}
    ///@param _pool is the address of the created pool
    function createPool(address tokenA, address tokenB, uint24 fee, uint160 sqrtPriceX96) external returns (address _pool);

    ///@dev Function to return the Liquidity provided
    ///@param _tokenId is the tokenId of the minted V3 position
    function getLiquidity(uint _tokenId) external view returns (uint128);

    ///@dev Function to get the Pair from the tokenId
    ///@param tokenId is the tokenId of the minted V3 position 
    ///@param _token0 is the first token address of the pair
    ///@param _token1 is the second token address of the pair
    // function _getTokens(uint256 tokenId) internal returns (address _token0, address _token1); 
    // {NOTICE THAT THIS FUNCTION IS INTERNAL}

    ///@dev Function to check metadata from the minted position
    ///@param tokenId is the tokenId of the minted V3 position 
    ///@param _token0 is the first token address of the pair
    ///@param _token1 is the second token address of the pair
    ///@param tokensOwed0 is the amount of fees to be redeemed of the first token of the pair
    ///@param tokensOwed1 is the amount of fees to be redeemed of the second token of the pair
    function checkFees(uint256 tokenId) external returns (address _token0, address _token1, uint128 tokensOwed0, uint128 tokensOwed1);


    ///@dev Function to return the tick based on the percentage on the current price inputted by the user
    ///@param _token0 is the address of the first token of the pair
    ///@param _token1 is the address of the second token of the pair
    ///@param _fee is the fee of the pool, as follows {0,05% = 500}
    ///@param _percentageLow is the percentage that you want to place your lower tick based on the current price {input like 0 - 100} {like currentPrice - 30%}
    ///@param _percentageUp is the percentage that you want to place your upper tick based on the current price {input like 0 - 100} {like currentPrice + 30%}
    ///@param tickLower is the returned tickLower for the mint param
    ///@param tickUpper is the returned tickUpper for the mint param
    // function _auxTickFromPercentage(address _token0, address _token1,uint24 _fee, uint _percentageLow, uint _percentageUp) internal returns (int24 tickLower, int24 tickUpper); 
    // {NOTICE THAT THIS FUNCTION IS INTERNAL}

    ///@dev Function to take the squareRoot of a number in solidity
    ///@param y is the original number
    ///@param z is the square rooted number
    // function sqrt(uint y) internal pure returns (uint z);
    //{NOTICE THAT THIS FUNCTION IS INTERNAL}


    ///--------------------------------------------------------------------------------------------------------
    /// SWAPS IF NEEDED {ERC20} {in order to do native token pool, first they have to be transformed into ERC20 on the contracts detailed at the beginner of this doc}
    ///--------------------------------------------------------------------------------------------------------

    ///@dev Function to do a direct swap if existis {use checkPool function to see if this direct swap is available}
    ///@param tokenIn is the token that will be fully consumed
    ///@param tokenOut is the token that will be received
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param amountIn is the amount of tokenIn you want to trade exactly
    function swapExactInputSingleHop(address tokenIn, address tokenOut, uint24 fee,uint amountIn) external;

    ///@dev Function to do a direct swap if existis {use checkPool function to see if this direct swap is available}
    ///@param tokenIn is the token that will be consumed
    ///@param tokenOut is the token that will be received exactly
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param amountOut is the amount of tokenOut you want to trade exactly
    ///@param amountInMax is the amount of tokenIn you want to trade in the max for the amountOut
    function swapExactOutputSingleHop(address tokenIn, address tokenOut, uint24 fee,uint amountOut, uint amountInMax) external;


    ///@dev Function to swap for WMatic
    function swapForWMatic() external payable; 
    ///--------------------------------------------------------------------------------------------------------
    /// SWAPS SIMULATION {ARE NOT SIMULATED OFF-CHAIN}
    ///--------------------------------------------------------------------------------------------------------

    ///@dev Funtions to simulate swapExactInputSingleHop
    ///@param tokenIn is the token that will be fully consumed
    ///@param tokenOut is the token that will be received
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param amountIn is the amount of tokenIn you want to trade exactlyv
    ///@param amountOut is the amount of tokenOut that the exact amount of tokenIn will be able to swap for
    ///@param sqrtPriceX96After is the sqrtPriceX96 after the liquidity change
    ///@param initializedTicksCrossed {we are not using this output}
    ///@param gasEstimate is the estimate gas needed for the swap
    function simulateInputSingle(address tokenIn, address tokenOut, uint24 fee,uint amountIn)
    external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

    ///@dev Funtions to simulate swapExactOutputSingleHop
    ///@param tokenIn is the token that will be consumed
    ///@param tokenOut is the token that will be received exactly
    ///@param fee is the fee of the pool, as follows {0,05% = 500}
    ///@param amountOut is the amount of tokenOut you want to trade exactly
    ///@param amountInMax is the amount of tokenIn you want to trade in the max for the amountOut
    ///@param amountIn is the amountIn needed
    ///@param sqrtPriceX96After is the sqrtPriceX96 after the liquidity change
    ///@param initializedTicksCrossed {we are not using this output}
    ///@param gasEstimate is the estimate gas needed for the swap
    function simulateOutputSingle(address tokenIn, address tokenOut, uint24 fee,uint amountOut, uint amountInMax)
    external returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}