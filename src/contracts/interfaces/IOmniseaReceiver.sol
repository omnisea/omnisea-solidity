// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IOmniseaReceiver {
    function omReceive(address collection, uint256 mintQuantity, uint256 nextTokenId, bytes memory payloadForCall) external;
}
