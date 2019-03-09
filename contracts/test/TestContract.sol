pragma solidity ^0.5.5;


contract TestOutOfGasContract {
    function() external {
        uint256 a = 1;
        while (true) {
            a++;
        }
    }
}
