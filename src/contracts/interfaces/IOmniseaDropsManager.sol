// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOmniseaDropsManager {
    function osea() external returns (IERC20);
    function minStake() external returns (uint256);
}
