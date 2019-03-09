pragma solidity ^0.5.0;

// Bytes library to concat and transform
// bytes arrays
library Bytes {
    // Concatenates two bytes array
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

    // Concatenates a bytes array and a bytes1
    function concat(bytes memory _a, bytes1 _b) internal pure returns (bytes memory _out) {
        return concat(_a, abi.encodePacked(_b));
    }

    // Concatenates 6 bytes arrays
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

    // Transforms a bytes1 into bytes
    function toBytes(bytes1 _a) internal pure returns (bytes memory) {
        return abi.encodePacked(_a);
    }

    // Transform a uint256 into bytes (last 8 bits)
    function toBytes1(uint256 _a) internal pure returns (bytes1 c) {
        assembly { c := shl(248, _a) }
    }

    // Adds a bytes1 and the last 8 bits of a uint256
    function plus(bytes1 _a, uint256 _b) internal pure returns (bytes1 c) {
        c = toBytes1(_b);
        assembly { c := add(_a, c) }
    }

    // Transforms a bytes into an array
    // it fails if _a has more than 20 bytes
    function toAddress(bytes memory _a) internal pure returns (address payable b) {
        require(_a.length <= 20);
        assembly {
            b := shr(mul(sub(32, mload(_a)), 8), mload(add(_a, 32)))
        }
    }

    function mostSignificantBit(uint256 x) internal pure returns (uint256) {        
        uint8 l = 0;
        uint8 h = 255;
        
        while (h > l) {
            uint8 m = uint8 ((uint16 (l) + uint16 (h)) >> 1);
            uint256 t = x >> m;
            if (t == 0) h = m - 1;
            else if (t > 1) l = m + 1;
            else return m;
        }
        
        return h;
    }

    function shrink(address _a) internal pure returns (bytes memory b) {
        uint256 abits = mostSignificantBit(uint256(_a)) + 1;
        uint256 abytes = abits / 8 + (abits % 8 == 0 ? 0 : 1);

        assembly {
            b := 0x0
            mstore(0x0, abytes)
            mstore(0x20, shl(mul(sub(32, abytes), 8), _a))
        }
    }
}
