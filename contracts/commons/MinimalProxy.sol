pragma solidity ^0.5.5;

import "./Bytes.sol";


library MinimalProxy {
    using Bytes for bytes1;
    using Bytes for bytes;

    // Minimal proxy contract
    // by Agusx1211
    bytes constant CODE1 = hex"60"; // + <size>                                   // Copy code to memory
    bytes constant CODE2 = hex"80600b6000396000f3";                               // Return and deploy contract
    bytes constant CODE3 = hex"3660008037600080366000";   // + <pushx> + <source> // Proxy, copy calldata and start delegatecall
    bytes constant CODE4 = hex"5af43d6000803e60003d9160"; // + <return jump>      // Do delegatecall and return jump
    bytes constant CODE5 = hex"57fd5bf3";                                         // Return proxy

    bytes1 constant BASE_SIZE = 0x1d;
    bytes1 constant PUSH_1 = 0x60;
    bytes1 constant BASE_RETURN_JUMP = 0x1b;

    // Returns the Init code to create a
    // Minimal proxy pointing to a given address
    function build(address _address) internal pure returns (bytes memory initCode) {
        return build(Bytes.shrink(_address));
    }

    function build(bytes memory _address) private pure returns (bytes memory initCode) {
        require(_address.length <= 20, "Address too long");
        initCode = Bytes.concat(
            CODE1,
            BASE_SIZE.plus(_address.length).toBytes(),
            CODE2,
            CODE3.concat(PUSH_1.plus(_address.length - 1)).concat(_address),
            CODE4.concat(BASE_RETURN_JUMP.plus(_address.length)),
            CODE5
        );
    }
}
