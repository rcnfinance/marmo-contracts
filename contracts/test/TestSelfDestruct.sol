pragma solidity ^0.5.5;


contract TestSelfDestruct {
    function() external {
        selfdestruct(msg.sender);
    }
}
