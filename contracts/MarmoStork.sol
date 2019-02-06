pragma solidity ^0.5.0;

import "./Marmo.sol";


library Bytes {
    function concat(bytes memory _baseBytes, bytes memory _valueBytes) internal pure returns (bytes memory _out) {
        uint256 blength = _baseBytes.length;
        uint256 vlength = _valueBytes.length;

        _out = new bytes(blength + vlength);

        uint256 i;
        uint256 j;

        for (i = 0; i < blength; i++) {
            _out[j++] = _baseBytes[i];
        }

        for (i = 0; i < vlength; i++) {
            _out[j++] = _valueBytes[i];
        }
    }
}


// solium-disable max-len
contract MarmoStork {
    // Compiled Proxy.sol
    bytes public constant BYTECODE_1 = hex"6080604052348015600f57600080fd5b50606780601d6000396000f3fe6080604052366000803760008036600073";
    bytes public constant BYTECODE_2 = hex"5af43d6000803e8015156036573d6000fd5b3d6000f3fea165627a7a7230582033b260661546dd9894b994173484da72335f9efc37248d27e6da483f15afc1350029";

    bytes public bytecode;
    bytes32 public hash;
    
    address public marmoSource;

    constructor() public {
        Marmo marmo = new Marmo();   // Create Marmo main instance
        marmo.init(address(1));      // Transfer to invalid address

        bytecode = Bytes.concat(     // Concat proxy bytecode
            Bytes.concat(
                BYTECODE_1, abi.encodePacked(marmo)
            ),
            BYTECODE_2
        );

        hash = keccak256(bytecode);   // Pre-calculate hash
        marmoSource = address(marmo); // Save Marmo main instance reference
    }
    
    function marmoOf(address _signer) external view returns (address) {
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

    function reveal(address _signer) external {
        bytes memory proxyCode = bytecode;
        Marmo p;

        assembly {
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        p.init(_signer);
    }
}
