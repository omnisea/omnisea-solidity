// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaPaymentsManager {
    function onPayment(address _payee, uint256 _paid, address _collection) external;
    function payout(address _recipient, uint256 _endTime) external;
    function refund(address _refundee, uint256 _endTime) external;
    function isFlagged(address _collection) external view returns (bool);
}
