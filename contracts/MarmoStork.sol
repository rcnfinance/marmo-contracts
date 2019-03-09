pragma solidity ^0.5.0;

import "./Marmo.sol";
import "./commons/Bytes.sol";

// MarmoStork creates all Marmo wallets
// every address has a designated marmo wallet
// and can send transactions by signing Meta-Tx (Intents)
//
// All wallets are proxies pointing to a single
// source contract, to make deployment costs viable
contract MarmoStork {
    using Bytes for address;
    using Bytes for bytes1;
    using Bytes for bytes;

    // Random Invalid signer address
    // Intents signed with this address are invalid
    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);

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

    // Bytecode to deploy marmo wallets
    bytes public bytecode;

    // Hash of the bytecode
    // used to calculate create2 result
    bytes32 public hash;

    // Marmo Source contract
    // all proxies point here
    address public marmo;

    // Creates a new MarmoStork (Marmo wallet Factory)
    // with wallets pointing to the _source contract reference
    // notice: _source may contain less than 20 bytes
    // the difference will be filled with 0s at the beginning of the address
    constructor(bytes memory _source) public {
        // Generate and save wallet creator bytecode using the provided '_source'
        bytecode = Bytes.concat(
            CODE1,
            BASE_SIZE.plus(_source.length).toBytes(),
            CODE2,
            CODE3.concat(PUSH_1.plus(_source.length - 1)).concat(_source),
            CODE4.concat(BASE_RETURN_JUMP.plus(_source.length)),
            CODE5
        );

        // Precalculate init_code hash
        hash = keccak256(bytecode);
        
        // Destroy the '_source' provided, if is not destroyed
        Marmo marmoc = Marmo(_source.toAddress());
        if (marmoc.signer() == address(0)) {
            marmoc.init(INVALID_ADDRESS);
        }

        // Validate, the signer of _source should be "INVALID_ADDRESS" (destroyed)
        require(marmoc.signer() == INVALID_ADDRESS, "Error init Marmo source");

        // Save the _source address, casting to address (160 bits)
        marmo = address(marmoc);
    }
    
    // Calculates the Marmo wallet for a given signer
    // the wallet contract will be deployed in a deterministic manner
    function marmoOf(address _signer) external view returns (address) {
        // CREATE2 address
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        bytes32(uint256(_signer)),
                        hash
                    )
                )
            )
        );
    }

    // Deploys the Marmo wallet of a given _signer
    // all ETH sent will be forwarded to the wallet
    function reveal(address _signer) external payable {
        // Load init code from storage
        bytes memory proxyCode = bytecode;

        // Create wallet proxy using CREATE2
        // use _signer as salt
        Marmo p;
        assembly {
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        // Init wallet with provided _signer
        // and forward all Ether
        p.init.value(msg.value)(_signer);
    }
}
