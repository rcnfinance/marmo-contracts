pragma solidity ^0.5.0;

import "./Marmo.sol";

contract NanoProxy {
    function _delegatedFwd(address _dst, bytes memory _calldata) internal {
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function() external payable {
        _delegatedFwd(address(0), msg.data);
    }
}

contract MarmoCreator {
    function create(address _signer) external {
        NanoProxy proxy = new NanoProxy();
        Marmo(address(proxy)).setSigner(_signer);
    }
}
