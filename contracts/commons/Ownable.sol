pragma solidity ^0.5.0;

contract Ownable {
    event SetOwner(address _owner);

    address public owner;

    /**
      @dev Setup function sets initial storage of contract.
      @param _owner List of signer.
    */
    function _init(address _owner) internal {
        require(owner == address(0), "Owner already defined");
        owner = _owner;
        emit SetOwner(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return _owner != address(0) && owner == _owner;
    }
}
