// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IBoreal {

    ///--------------------------------------------------------------------------------------------------------
    /// LIQUIDITY FOR UNISWAP
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
    /// SWAPS IF NEEDED {ERC20} {in order to do native token pool, first they have to be transformed into ERC20 on the contracts detailed at the beginner of this doc}
    ///--------------------------------------------------------------------------------------------------------
    ///--------------------------------------------------------------------------------------------------------
    /// FOR SWAPS USING NATIVE TOKEN, PLEASE USE THE WRAPPED VERSION AND AT THE END UNWARP IT
    ///--------------------------------------------------------------------------------------------------------

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


    ///@dev Function to swap for WNATIVE TOKEN
    function swapForWNATIVE() external payable; 


    ///@dev Function to swap WNATIVE TOKEN for NATIVE TOKEN
    ///@notice Remind that the msg.sender has to `approve` the boral address to transfer those wrapped tokens
    function swapFromWNATIVE(uint256 amount) external;

    ///--------------------------------------------------------------------------------------------------------
    /// STAKING FOR LIDO
    ///--------------------------------------------------------------------------------------------------------

    ///@dev Deposit ETH and get stETH (REBALANCE BASED TOKEN OF LIDO)
    ///@param _amount is the amount of shares of stETH
    function depositForStETH() external payable returns(uint256 _amount);

    ///@dev Deposit ETH and get wstETH (ERC20 BASED TOKEN OF LIDO)
    function depositForWstETH() external payable;

    ///@notice The user needs to approve boreal contract to transfer the _amount of stETH on lido's contract
    ///@dev Takes stETH and returns wstETH to the msg.sender's wallet
    ///@param _amount is the amount os stETH to be wrapped into wstETH
    function wrapStETH(uint256 _amount) external;

    ///@notice The user needs to approve boreal contract to transfer the _amount of wstETH
    ///@dev Takes wstETH and returns stETH to the msg.sender's wallet
    ///@param _amount is the amount os wstETH to be unwraped into stETH
    function unwrapWstETH(uint256 _amount) external;

    ///@notice The user needs to approve boreal contract to transfer the _amounts of stETH
    ///@notice Even though the _amounts is dynamic array, USE ONLY ONE VALUE
    ///@notice WITHDRAW ON LIDO TAKES 2 STEPS: 
    ///@notice 1. QUEUE (TRADES stETH to an NFT with the id being the requestID)
    ///@notice 2. EXECUTE (TRADES NFT to the amount of ETH with the NFT id being the requestID)
    ///@dev Function that takes the stETH and generates the NFT of the requestID
    ///@param _amounts is the amount os stETH to withdraw
    ///@param _requestID is the NFT id of the withdrawal request
    function queueSingleWithdraw(uint256[] calldata _amounts) external returns(uint256 _requestID);

    ///@notice The user needs to approve boreal contract to transfer the _requestID nft of the withdraw
    ///@notice THIS IS STEP 2 OF THE WITHDRAWAL FLOW FOR LIDO'S stETH
    ///@dev Function that takes NFT of withdraw queue and returns ETH to the msg.sender's wallet
    ///@param _requestID is the NFT id that represents the withdraw request
    function executeWithdraw(uint256 _requestID) external;
}
