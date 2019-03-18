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

    function testConcatSmall() external {
        bytes memory a = hex"7302";
        bytes memory b = hex"29c2fbf7b3";
        Assert.equal(
            keccak256(Bytes.concat(a, b)),
            keccak256(bytes(hex"730229c2fbf7b3")),
            "Should concat bytes"
        );
    }

    function testConcatEmpty() external {
        bytes memory a = hex"7302";
        bytes memory b = hex"";
        Assert.equal(
            keccak256(Bytes.concat(a, b)),
            keccak256(bytes(hex"7302")),
            "Should concat bytes"
        );
        Assert.equal(
            keccak256(Bytes.concat(b, a)),
            keccak256(bytes(hex"7302")),
            "Should concat bytes"
        );
    }

    function testConcatLarge() external {
        bytes memory a = hex"0a095992a7429c2fbf7b3754ab4b09f270f34c327ce004ab3b2906f7c3573027";
        bytes memory b = hex"14970b8815c3da10bbeb31c1d3e330009950ca47aa145b37356f62ca7a4bef40";
        Assert.equal(
            keccak256(Bytes.concat(a, b)),
            keccak256(bytes(hex"0a095992a7429c2fbf7b3754ab4b09f270f34c327ce004ab3b2906f7c357302714970b8815c3da10bbeb31c1d3e330009950ca47aa145b37356f62ca7a4bef40")),
            "Should concat bytes"
        );
    }

    function testConcatLarge2() external {
        bytes memory a = hex"0a095992a7429c2fbf7b3754ab4b09f270f34c327ce004ab3b2906f7c3573027e004ab3b2906f7c3573027";
        bytes memory b = hex"000995014970b8815c3da10bbeb31c1d3e330009950ca47aa145b37356f62ca7a4bef4";
        Assert.equal(
            keccak256(Bytes.concat(a, b)),
            keccak256(bytes(hex"0a095992a7429c2fbf7b3754ab4b09f270f34c327ce004ab3b2906f7c3573027e004ab3b2906f7c3573027000995014970b8815c3da10bbeb31c1d3e330009950ca47aa145b37356f62ca7a4bef4")),
            "Should concat bytes"
        );
    }

    function testConcatSix() external {
        bytes memory b1 = hex"A1";
        bytes memory b2 = hex"B2";
        bytes memory b3 = hex"C3";
        bytes memory b4 = hex"D4";
        bytes memory b5 = hex"E5";
        bytes memory b6 = hex"F6";

        Assert.equal(
            keccak256(Bytes.concat(
                b1,
                b2,
                b3,
                b4,
                b5,
                b6
            )),
            keccak256(bytes(hex"A1B2C3D4E5F6")),
            "Should concat bytes six"
        );
    }
}
