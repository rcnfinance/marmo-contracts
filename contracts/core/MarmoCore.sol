pragma solidity ^0.5.0;

import "./../commons/Signable.sol";
import "./../commons/SignatureDeserializer.sol";

contract MarmoCore is Signable {
    
    mapping(bytes32 => address) public relayerOf;
    mapping(bytes32 => bool) public isCanceled;

    event Relayed(
        bytes32 _id,
        bytes32[] _dependencies,
        address _to,
        uint256 _value,
        bytes _data,
        bytes32 _salt,
        address _relayer,
        bool _success
    );
    event Canceled(
        bytes32 _id
    );

    function setup(address _signer) public {
        initSigner(_signer);
    }

    function encodeTransactionData(
        bytes32[] memory _dependencies,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _minGasLimit,
        uint256 _maxGasPrice,
        bytes32 _salt
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
                _salt
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
        bytes memory _signature
    ) public returns (
        bool success,
        bytes memory data 
    ) {
        bytes32 hashTransaction = encodeTransactionData(_dependencies, _to, _value, _data, _minGasLimit, _maxGasPrice, _salt);
        
        require(tx.gasprice <= _maxGasPrice);
        require(!isCanceled[hashTransaction], "Transaction was canceled");
        require(relayerOf[hashTransaction] == address(0), "Transaction already relayed");
        require(dependenciesSatisfied(_dependencies), "Parent relay not found");
        validateHashTransaction(hashTransaction, _signature);

        require(gasleft() > _minGasLimit);
        (success, data) = _to.call.value(_value)(_data);

        relayerOf[hashTransaction] = msg.sender;
        
        emit Relayed(
            hashTransaction,
            _dependencies,
            _to,
            _value,
            _data,
            _salt,
            msg.sender,
            success
        );
    }

    function cancel(bytes32 _hashTransaction) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");
        require(relayerOf[_hashTransaction] == address(0), "Transaction was already relayed");
        isCanceled[_hashTransaction] = true;
    }

    function validateHashTransaction(bytes32 transactionHash, bytes memory signature) internal view {
        address currentSigner = SignatureDeserializer.recoverKey(transactionHash, signature);
        require(isSigner(currentSigner), "Signature not provided by signer");
    }
    
    function() external payable {}
}