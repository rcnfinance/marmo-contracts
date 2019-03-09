pragma solidity ^0.5.5;

import "truffle/Assert.sol";
import "../contracts/commons/Bytes.sol";


contract TestBytes {
    event D(address _a);

    function testToAddress20() external {
        bytes memory adhex = hex"23c596aaa2e815f265f7e5e7344ac5faa21d387c";
        Assert.equal(
            Bytes.toAddress(adhex),
            address(0x23c596AaA2e815F265F7e5E7344aC5faA21d387C),
            "Should decode address of 20 bytes"
        );
    }

    function testToAddressLess20() external {
        bytes memory adhex = hex"faa21d387c";
        emit D(Bytes.toAddress(adhex));
        Assert.equal(
            Bytes.toAddress(adhex),
            address(0x000000000000000000000000000000fAa21D387c),
            "Should decode address of 5 bytes"
        );
    }

    function testShrink() external {
        address a = address(0x000000000000000000000000000000fAa21D387c);
        bytes memory ashrunk = Bytes.shrink(a);
        Assert.equal(
            keccak256(hex"faa21d387c"),
            keccak256(ashrunk),
            "Should shrink the address"
        );
        Assert.equal(
            Bytes.toAddress(ashrunk),
            a,
            "Should shrink and expand address"
        );
    }

    function testShirnkSetFloor() external {
        bytes memory ashrunk;
        for(uint256 i = 0; i < 950; i++) {
            ashrunk = Bytes.shrink(address(i));
            Assert.equal(
                address(i),
                Bytes.toAddress(ashrunk),
                "Should shrink and expand address"
            );
        }
    }

    function testShirnkSetCeiling() external {
        bytes memory ashrunk;
        uint256 to = (uint256(0) - 1) - 950;
        for(uint256 i = (uint256(0) - 1); i > to; i--) {
            ashrunk = Bytes.shrink(address(i));
            Assert.equal(
                address(i),
                Bytes.toAddress(ashrunk),
                "Should shrink and expand address"
            );
        }
    }
}
