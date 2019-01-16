pragma solidity ^0.5.0;

import "./commons/SigUtils.sol";
import "./commons/Ownable.sol";

contract Marmo is Ownable {
    event Relayed(
        bytes32 indexed _id,
        bytes32[] _dependencies,
        address _to,
        uint256 _value,
        bytes _data,
        bytes32 _salt,
        uint256 _expiration,
        bool _success
    );

    event Canceled(
        bytes32 _id
    );

    mapping(bytes32 => address) public relayerOf;
    mapping(bytes32 => bool) public isCanceled;

    function init(address _owner) external {
        _init(_owner);
    }

    function encodeTransactionData(
        bytes32[] memory _dependencies,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _minGasLimit,
        uint256 _maxGasPrice,
        bytes32 _salt,
        uint256 _expiration
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                this,
                keccak256(abi.encodePacked(_dependencies)),
                _to,
                _value,
                keccak256(_data),
                _minGasLimit,
                _maxGasPrice,
                _salt,
                _expiration
            )
        );
    }

    function dependenciesSatisfied(bytes32[] memory _dependencies) internal view returns (bool) {
        for (uint256 i; i < _dependencies.length; i++) {
            if (relayerOf[_dependencies[i]] == address(0)) return false;
        }
        
        return true;
    }

    function relay(
        bytes32[] memory _dependencies,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _minGasLimit,
        uint256 _maxGasPrice,
        bytes32 _salt,
        uint256 _expiration,
        bytes memory _signature
    ) public returns (
        bool success,
        bytes memory data 
    ) {
        bytes32 id = encodeTransactionData(_dependencies, _to, _value, _data, _minGasLimit, _maxGasPrice, _salt, _expiration);
        
        require(now < _expiration, "Intent is expired");
        require(tx.gasprice <= _maxGasPrice);
        require(!isCanceled[id], "Transaction was canceled");
        require(relayerOf[id] == address(0), "Transaction already relayed");
        require(dependenciesSatisfied(_dependencies), "Parent relay not found");
        require(msg.sender == owner || owner == SigUtils.ecrecover2(id, _signature), "Invalid signature");

        require(gasleft() > _minGasLimit);
        (success, data) = _to.call.value(_value)(_data);

        relayerOf[id] = msg.sender;
        
        emit Relayed(
            id,
            _dependencies,
            _to,
            _value,
            _data,
            _salt,
            _expiration,
            success
        );
    }

    function cancel(bytes32 _hashTransaction) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");
        require(relayerOf[_hashTransaction] == address(0), "Transaction was already relayed");
        isCanceled[_hashTransaction] = true;
    }
    
    function() external payable {}
}
