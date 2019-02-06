pragma solidity ^0.5.0;


contract Ownable {
    address public owner;

    /**
      @dev Setup function sets initial storage of contract.
      @param _owner List of signer.
    */
    function _init(address _owner) internal {
        require(owner == address(0), "Owner already defined");
        owner = _owner;
    }
}
