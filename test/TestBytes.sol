pragma solidity ^0.5.0;

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
}
