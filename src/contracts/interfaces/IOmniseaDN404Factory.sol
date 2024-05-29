// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404Factory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
}
