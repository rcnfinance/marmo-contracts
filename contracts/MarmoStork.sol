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

    function concat(bytes memory _a, bytes1 _b) internal pure returns (bytes memory _out) {
        return concat(_a, abi.encodePacked(_b));
    }

    function concat(
        bytes memory _a,
        bytes memory _b,
        bytes memory _c,
        bytes memory _d,
        bytes memory _e,
        bytes memory _f
    ) internal pure returns (bytes memory) {
        return concat(_a, concat(_b, concat(_c, concat(_d, concat(_e, _f)))));
    }

    function toBytes(bytes1 _a) internal pure returns (bytes memory) {
        return abi.encodePacked(_a);
    }

    function toBytes1(uint256 _a) internal pure returns (bytes1 c) {
        assembly { c := shl(248, _a) }
    }

    function plus(bytes1 _a, uint256 _b) internal pure returns (bytes1 c) {
        c = toBytes1(_b);
        assembly { c := add(_a, c) }
    }

    function toAddress(bytes memory _a) internal pure returns (address payable b) {
        require(_a.length <= 20, "A");
        assembly {
            b := mload(add(_a, 20))
        }
    }
}


// solium-disable max-len
contract MarmoStork {
    using Bytes for address;
    using Bytes for bytes1;
    using Bytes for bytes;

    // Minimal proxy contract
    // by Agusx1211
    bytes constant CODE1 = hex"60"; // + <size>                                   // Copy code to memory
    bytes constant CODE2 = hex"80600c6000396000f3fe";                             // Return and deploy contract
    bytes constant CODE3 = hex"3660008037600080366000";   // + <pushx> + <source> // Proxy, copy calldata and start delegatecall
    bytes constant CODE4 = hex"5af43d6000803e60003d9160"; // + <return jump>      // Do delegatecall and return jump
    bytes constant CODE5 = hex"57fd5bf3";                                         // Return proxy

    bytes1 constant BASE_SIZE = 0x1d;
    bytes1 constant PUSH_1 = 0x60;
    bytes1 constant BASE_RETURN_JUMP = 0x1b;

    bytes public bytecode;

    bytes32 public hash;    
    address public marmo;

    constructor(bytes memory _source) public {
        bytecode = Bytes.concat(
            CODE1,
            BASE_SIZE.plus(_source.length).toBytes(),
            CODE2,
            CODE3.concat(PUSH_1.plus(_source.length - 1)).concat(_source),
            CODE4.concat(BASE_RETURN_JUMP.plus(_source.length)),
            CODE5
        );

        hash = keccak256(bytecode);
        
        Marmo marmoc = Marmo(_source.toAddress());
        if (marmoc.signer() == address(0)) {
            marmoc.init(address(1));
        }

        require(marmoc.signer() == address(1), "init");
        marmo = address(marmoc);
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

    function reveal(address _signer) external payable {
        bytes memory proxyCode = bytecode;
        Marmo p;

        assembly {
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        p.init.value(msg.value)(_signer);
    }
}
