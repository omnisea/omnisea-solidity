// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OmniseaERC721Proxy {
    fallback() external payable {
        _delegate(address(0xdDe8B33735F3eb5f151E1De4E3108c940dB0d837));
    }

    receive() external payable {
        _delegate(address(0xdDe8B33735F3eb5f151E1De4E3108c940dB0d837));
    }

    function _delegate(address _proxyTo) internal {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _proxyTo, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
