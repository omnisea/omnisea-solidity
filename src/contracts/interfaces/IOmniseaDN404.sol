// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404 {
    function initialize(CreateParams memory params, address _owner, address _manager, address _scheduler) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external returns (uint256);
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function owner() external view returns (address);
    function dropsManager() external view returns (address);
    function endTime() external view returns (uint256);
}
