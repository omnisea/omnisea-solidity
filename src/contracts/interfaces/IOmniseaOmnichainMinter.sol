// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IOmniseaOmnichainMinter {
    event MintToChain(uint16 indexed _dstChainId, address indexed _collection, address indexed _minter);
    event MintFromChain(uint16 indexed _srcChainId, address indexed _collection, address indexed _minter);
}
