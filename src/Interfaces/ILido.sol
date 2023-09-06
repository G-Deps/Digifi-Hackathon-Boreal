// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;
import "./ILidoLocator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Liquid staking pool implementation
*
* Lido is an Ethereum liquid staking protocol solving the problem of frozen staked ether on Consensus Layer
* being unavailable for transfers and DeFi on Execution Layer.
*
* Since balances of all token holders change when the amount of total pooled Ether
* changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
* events upon explicit transfer between holders. In contrast, when Lido oracle reports
* rewards, no Transfer events are generated: doing so would require emitting an event
* for each token holder and thus running an unbounded loop.
*
* ---
* NB: Order of inheritance must preserve the structured storage layout of the previous versions.
*
* @dev Lido is derived from `StETHPermit` that has a structured storage:
* SLOT 0: mapping (address => uint256) private shares (`StETH`)
* SLOT 1: mapping (address => mapping (address => uint256)) private allowances (`StETH`)
* SLOT 2: mapping(address => uint256) internal noncesByAddress (`StETHPermit`)
*
* `Versioned` and `AragonApp` both don't have the pre-allocated structured storage.
*/
interface ILido is IERC20{
  

    // Staking was paused (don't accept user's ether submits)
    event StakingPaused();
    // Staking was resumed (accept user's ether submits)
    event StakingResumed();
    // Staking limit was set (rate limits user's submits)
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    // Staking limit was removed
    event StakingLimitRemoved();

    // Emits when validators number delivered by the oracle
    event CLValidatorsUpdated(
        uint256 indexed reportTimestamp,
        uint256 preCLValidators,
        uint256 postCLValidators
    );

    // Emits when var at `DEPOSITED_VALIDATORS_POSITION` changed
    event DepositedValidatorsChanged(
        uint256 depositedValidators
    );

    // Emits when oracle accounting report processed
    event ETHDistributed(
        uint256 indexed reportTimestamp,
        uint256 preCLBalance,
        uint256 postCLBalance,
        uint256 withdrawalsWithdrawn,
        uint256 executionLayerRewardsWithdrawn,
        uint256 postBufferedEther
    );

    // Emits when token rebased (total supply and/or total shares were changed)
    event TokenRebased(
        uint256 indexed reportTimestamp,
        uint256 timeElapsed,
        uint256 preTotalShares,
        uint256 preTotalEther,
        uint256 postTotalShares,
        uint256 postTotalEther,
        uint256 sharesMintedAsFees
    );

    // Lido locator set
    event LidoLocatorSet(address lidoLocator);

    // The amount of ETH withdrawn from LidoExecutionLayerRewardsVault to Lido
    event ELRewardsReceived(uint256 amount);

    // The amount of ETH withdrawn from WithdrawalVault to Lido
    event WithdrawalsReceived(uint256 amount);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `amount` of ether was sent to the deposit_contract.deposit function
    event Unbuffered(uint256 amount);

    /**
    * @dev As AragonApp, Lido contract must be initialized with following variables:
    *      NB: by default, staking and the whole Lido pool are in paused state
    *
    * The contract's balance must be non-zero to allow initial holder bootstrap.
    *
    * @param _lidoLocator lido locator contract
    * @param _eip712StETH eip712 helper contract for StETH
    */
    function initialize(address _lidoLocator, address _eip712StETH)
        external
        payable;

    /**
     * @notice A function to finalize upgrade to v2 (from v1). Can be called only once
     * @dev Value "1" in CONTRACT_VERSION_POSITION is skipped due to change in numbering
     *
     * The initial protocol token holder must exist.
     *
     * For more details see https://github.com/lidofinance/lido-improvement-proposals/blob/develop/LIPS/lip-10.md
     */
    function finalizeUpgrade_v2(address _lidoLocator, address _eip712StETH) external;

    /**
     * @notice Stops accepting new Ether to the protocol
     *
     * @dev While accepting new Ether is stopped, calls to the `submit` function,
     * as well as to the default payable function, will revert.
     *
     * Emits `StakingPaused` event.
     */
    function pauseStaking() external ;

    /**
     * @notice Resumes accepting new Ether to the protocol (if `pauseStaking` was called previously)
     * NB: Staking could be rate-limited by imposing a limit on the stake amount
     * at each moment in time, see `setStakingLimit()` and `removeStakingLimit()`
     *
     * @dev Preserves staking limit if it was set previously
     *
     * Emits `StakingResumed` event
     */
    function resumeStaking() external;

    /**
     * @notice Sets the staking rate limit
     *
     * ▲ Stake limit
     * │.....  .....   ........ ...            ....     ... Stake limit = max
     * │      .       .        .   .   .      .    . . .
     * │     .       .              . .  . . .      . .
     * │            .                .  . . .
     * │──────────────────────────────────────────────────> Time
     * │     ^      ^          ^   ^^^  ^ ^ ^     ^^^ ^     Stake events
     *
     * @dev Reverts if:
     * - `_maxStakeLimit` == 0
     * - `_maxStakeLimit` >= 2^96
     * - `_maxStakeLimit` < `_stakeLimitIncreasePerBlock`
     * - `_maxStakeLimit` / `_stakeLimitIncreasePerBlock` >= 2^32 (only if `_stakeLimitIncreasePerBlock` != 0)
     *
     * Emits `StakingLimitSet` event
     *
     * @param _maxStakeLimit max stake limit value
     * @param _stakeLimitIncreasePerBlock stake limit increase per single block
     */
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external;

    /**
     * @notice Removes the staking rate limit
     *
     * Emits `StakingLimitRemoved` event
     */
    function removeStakingLimit() external;

    /**
     * @notice Check staking state: whether it's paused or not
     */
    function isStakingPaused() external view returns (bool);


    /**
     * @notice Returns how much Ether can be staked in the current block
     * @dev Special return values:
     * - 2^256 - 1 if staking is unlimited;
     * - 0 if staking is paused or if limit is exhausted.
     */
    function getCurrentStakeLimit() external view returns (uint256) ;
    /**
     * @notice Returns full info about current stake limit params and state
     * @dev Might be used for the advanced integration requests.
     * @return isStakingPaused staking pause state (equivalent to return of isStakingPaused())
     * @return isStakingLimitSet whether the stake limit is set
     * @return currentStakeLimit current stake limit (equivalent to return of getCurrentStakeLimit())
     * @return maxStakeLimit max stake limit
     * @return maxStakeLimitGrowthBlocks blocks needed to restore max stake limit from the fully exhausted state
     * @return prevStakeLimit previously reached stake limit
     * @return prevStakeBlockNumber previously seen block number
     */
    function getStakeLimitFullInfo()
        external
        view
        returns (
            bool isStakingPaused,
            bool isStakingLimitSet,
            uint256 currentStakeLimit,
            uint256 maxStakeLimit,
            uint256 maxStakeLimitGrowthBlocks,
            uint256 prevStakeLimit,
            uint256 prevStakeBlockNumber
        );

    /**
    * @notice Send funds to the pool
    * @dev Users are able to submit their funds by transacting to the fallback function.
    * Unlike vanilla Ethereum Deposit contract, accepting only 32-Ether transactions, Lido
    * accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
    * deposit() and pushes them to the Ethereum Deposit contract.
    */
    // solhint-disable-next-line no-complex-fallback
    // function() external payable;

    /**
     * @notice Send funds to the pool with optional _referral parameter
     * @dev This function is alternative way to submit funds. Supports optional referral address.
     * @return Amount of StETH shares generated
     */
    function submit(address _referral) external payable returns (uint256);

    /**
     * @notice A payable function for execution layer rewards. Can be called only by `ExecutionLayerRewardsVault`
     * @dev We need a dedicated function because funds received by the default payable function
     * are treated as a user deposit
     */
    function receiveELRewards() external payable;

    /**
    * @notice A payable function for withdrawals acquisition. Can be called only by `WithdrawalVault`
    * @dev We need a dedicated function because funds received by the default payable function
    * are treated as a user deposit
    */
    function receiveWithdrawals() external payable ;

    /**
     * @notice Stop pool routine operations
     */
    function stop() external;

    /**
     * @notice Resume pool routine operations
     * @dev Staking is resumed after this call using the previously set limits (if any)
     */
    function resume() external;

    /**
     * The structure is used to aggregate the `handleOracleReport` provided data.
     * @dev Using the in-memory structure addresses `stack too deep` issues.
     */
    struct OracleReportedData {
        // Oracle timings
        uint256 reportTimestamp;
        uint256 timeElapsed;
        // CL values
        uint256 clValidators;
        uint256 postCLBalance;
        // EL values
        uint256 withdrawalVaultBalance;
        uint256 elRewardsVaultBalance;
        uint256 sharesRequestedToBurn;
        // Decision about withdrawals processing
        uint256[] withdrawalFinalizationBatches;
        uint256 simulatedShareRate;
    }

    /**
     * The structure is used to preload the contract using `getLidoLocator()` via single call
     */
    struct OracleReportContracts {
        address accountingOracle;
        address elRewardsVault;
        address oracleReportSanityChecker;
        address burner;
        address withdrawalQueue;
        address withdrawalVault;
        address postTokenRebaseReceiver;
    }


    /**
     * @notice Unsafely change deposited validators
     *
     * The method unsafely changes deposited validator counter.
     * Can be required when onboarding external validators to Lido
     * (i.e., had deposited before and rotated their type-0x00 withdrawal credentials to Lido)
     *
     * @param _newDepositedValidators new value
     */
    function unsafeChangeDepositedValidators(uint256 _newDepositedValidators) external;

    /**
     * @notice Overrides default AragonApp behaviour to disallow recovery.
     */
    function transferToVault(address /* _token */) external;

    /**
    * @notice Get the amount of Ether temporary buffered on this contract balance
    * @dev Buffered balance is kept on the contract from the moment the funds are received from user
    * until the moment they are actually sent to the official Deposit contract.
    * @return amount of buffered funds in wei
    */
    function getBufferedEther() external view returns (uint256);

    /**
     * @notice Get total amount of execution layer rewards collected to Lido contract
     * @dev Ether got through LidoExecutionLayerRewardsVault is kept on this contract's balance the same way
     * as other buffered Ether is kept (until it gets deposited)
     * @return amount of funds received as execution layer rewards in wei
     */
    function getTotalELRewardsCollected() external view returns (uint256);
    

    /**
     * @notice Gets authorized oracle address
     * @return address of oracle contract
     */
    function getLidoLocator() external view returns (ILidoLocator);

    /**
    * @notice Returns the key values related to Consensus Layer side of the contract. It historically contains beacon
    * @return depositedValidators - number of deposited validators from Lido contract side
    * @return beaconValidators - number of Lido validators visible on Consensus Layer, reported by oracle
    * @return beaconBalance - total amount of ether on the Consensus Layer side (sum of all the balances of Lido validators)
    *
    * @dev `beacon` in naming still here for historical reasons
    */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);

    /**
     * @dev Check that Lido allows depositing buffered ether to the consensus layer
     * Depends on the bunker state and protocol's pause state
     */
    function canDeposit() external view returns (bool);

    /**
     * @dev Returns depositable ether amount.
     * Takes into account unfinalized stETH required by WithdrawalQueue
     */
    function getDepositableEther() external view returns (uint256);

    /**
     * @dev Invokes a deposit call to the Staking Router contract and updates buffered counters
     * @param _maxDepositsCount max deposits count
     * @param _stakingModuleId id of the staking module to be deposited
     * @param _depositCalldata module calldata
     */
    function deposit(uint256 _maxDepositsCount, uint256 _stakingModuleId, bytes memory _depositCalldata) external;

    /// DEPRECATED PUBLIC METHODS

    /**
     * @notice Returns current withdrawal credentials of deposited validators
     * @dev DEPRECATED: use StakingRouter.getWithdrawalCredentials() instead
     */
    function getWithdrawalCredentials() external view returns (bytes32);

    /**
     * @notice Returns legacy oracle
     * @dev DEPRECATED: the `AccountingOracle` superseded the old one
     */
    function getOracle() external view returns (address);

    /**
     * @notice Returns the treasury address
     * @dev DEPRECATED: use LidoLocator.treasury()
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns current staking rewards fee rate
     * @dev DEPRECATED: Now fees information is stored in StakingRouter and
     * with higher precision. Use StakingRouter.getStakingFeeAggregateDistribution() instead.
     * @return totalFee total rewards fee in 1e4 precision (10000 is 100%). The value might be
     * inaccurate because the actual value is truncated here to 1e4 precision.
     */
    function getFee() external view returns (uint16 totalFee);

    /**
     * @notice Returns current fee distribution, values relative to the total fee (getFee())
     * @dev DEPRECATED: Now fees information is stored in StakingRouter and
     * with higher precision. Use StakingRouter.getStakingFeeAggregateDistribution() instead.
     * @return treasuryFeeBasisPoints return treasury fee in TOTAL_BASIS_POINTS (10000 is 100% fee) precision
     * @return insuranceFeeBasisPoints always returns 0 because the capability to send fees to
     * insurance from Lido contract is removed.
     * @return operatorsFeeBasisPoints return total fee for all operators of all staking modules in
     * TOTAL_BASIS_POINTS (10000 is 100% fee) precision.
     * Previously returned total fee of all node operators of NodeOperatorsRegistry (Curated staking module now)
     * The value might be inaccurate because the actual value is truncated here to 1e4 precision.
     */
    function getFeeDistribution()
        external view
        returns (
            uint16 treasuryFeeBasisPoints,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
    );

    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}
