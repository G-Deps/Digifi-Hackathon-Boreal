// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;
interface IwithdrawalQueue{


/// @notice Request the batch of stETH for withdrawal. Approvals for the passed amounts should be done before.
    /// @param _amounts an array of stETH amount values.
    ///  The standalone withdrawal request will be created for each item in the passed list.
    /// @param _owner address that will be able to manage the created requests.
    ///  If `address(0)` is passed, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal request ids
    function requestWithdrawals(uint256[] calldata _amounts, address _owner) external returns (uint256[] memory requestIds);

    /// @notice Request the batch of wstETH for withdrawal. Approvals for the passed amounts should be done before.
    /// @param _amounts an array of wstETH amount values.
    ///  The standalone withdrawal request will be created for each item in the passed list.
    /// @param _owner address that will be able to manage the created requests.
    ///  If `address(0)` is passed, `msg.sender` will be used as an owner.
    /// @return requestIds an array of the created withdrawal request ids
    function requestWithdrawalsWstETH(uint256[] calldata _amounts, address _owner) external returns (uint256[] memory requestIds);



    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address _owner) external view returns (uint256);

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 _requestId) external view returns (address);

    function transferFrom(address _from, address _to, uint256 _requestId) external;

    /// @dev See {IERC721-approve}.
    function approve(address _to, uint256 _requestId) external;

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 _requestId) external view returns (address);
    
}