pragma solidity ^0.5.2;


contract TestSelfDestruct {
    function() external {
        selfdestruct(msg.sender);
    }
}
