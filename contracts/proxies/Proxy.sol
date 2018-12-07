pragma solidity ^0.5.0;

/**
  @title Proxy - Generic proxy contract.
*/
contract Proxy {
    
    /** 
      @dev Constructor function sets address of marmo instance contract.
      @param _instance marmo instance address.
    */
    constructor(address _instance) public {
        require(_instance != address(0), "Invalid marmo instance address provided");
        assembly {
            sstore(0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c2, _instance)
        }
    }

    function () external payable {
        assembly {
            let instance := sload(0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c2)
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)
            
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, instance, 0, calldatasize, 0, 0)
            
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)
            
            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }
}