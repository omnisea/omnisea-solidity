// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/erc404/ERC404Structs.sol";

interface IOmniseaERC404Factory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
}
