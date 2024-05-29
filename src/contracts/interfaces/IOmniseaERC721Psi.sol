// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {CreateParams} from "../structs/erc721/ERC721Structs.sol";

/**
 * @dev Interface of the IOmniseaUniversalONFT: Universal ONFT Core through delegation
 */
interface IOmniseaERC721Psi is IERC165 {
    function initialize(CreateParams memory params, address _owner, address _dropsManagerAddress, address _scheduler) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function owner() external view returns (address);
    function dropsManager() external view returns (address);
    function endTime() external view returns (uint256);
}
