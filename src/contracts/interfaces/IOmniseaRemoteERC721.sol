// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { BasicCollectionParams } from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaRemoteERC721 is IERC721 {
    function initialize(BasicCollectionParams memory _collectionParams) external;
    function mint(address owner, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}
