// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {EncodedSendParams} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaONFTReceiver {
    function onONFTReceived(uint16 _srcChainId, EncodedSendParams memory _sendParams) external;
}
