pragma solidity ^0.5.5;

import "./Marmo.sol";
import "./commons/MinimalProxy.sol";


// MarmoStork creates all Marmo wallets
// every address has a designated marmo wallet
// and can send transactions by signing Meta-Tx (Intents)
//
// All wallets are proxies pointing to a single
// source contract, to make deployment costs viable
contract MarmoStork {
    // Random Invalid signer address
    // Intents signed with this address are invalid
    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);

    // Prefix of create2 address formula (EIP-1014)
    bytes1 private constant CREATE2_PREFIX = byte(0xff);

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
    constructor(address payable _source) public {
        // Generate and save wallet creator bytecode using the provided '_source'
        bytecode = MinimalProxy.build(_source);

        // Precalculate init_code hash
        hash = keccak256(bytecode);
        
        // Destroy the '_source' provided, if is not destroyed
        Marmo marmoc = Marmo(_source);
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
                        CREATE2_PREFIX,
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
