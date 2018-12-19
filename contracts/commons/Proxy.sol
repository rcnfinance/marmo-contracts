pragma solidity ^0.5.0;

/**
  @title Proxy - Generic proxy contract.
*/
contract Proxy {
    function () external payable {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)
            
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // replace 0x0 with delegated address
            let result := delegatecall(gas, 0x0000000000000000000000000000000000000000, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)
            
            if iszero(result) {
                revert(0, returndatasize)
            }
            
            return (0, returndatasize)
        }
    }
}
