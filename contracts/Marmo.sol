pragma solidity ^0.5.0;

import "./commons/SigUtils.sol";
import "./commons/Ownable.sol";


contract Marmo is Ownable {
    uint256 private constant EXTRA_GAS = 21000;

    event Relayed(
        bytes32 indexed _id,
        bytes _dependencies,
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

    // [1 bit (canceled) 95 bits (block) 160 bits (relayer)]
    mapping(bytes32 => bytes32) private intentReceipt;

    function() external payable {}

    function init(address _owner) external {
        _init(_owner);
    }

    function relayedBy(bytes32 _id) external view returns (address _relayer) {
        (,,_relayer) = _decodeReceipt(intentReceipt[_id]);
    }

    function relayedAt(bytes32 _id) external view returns (uint256 _block) {
        (,_block,) = _decodeReceipt(intentReceipt[_id]);
    }

    function isCanceled(bytes32 _id) external view returns (bool _canceled) {
        (_canceled,,) = _decodeReceipt(intentReceipt[_id]);
    }

    function cancel(bytes32 _id) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");
        if (intentReceipt[_id] != bytes32(0)) {
            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[_id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }

        intentReceipt[_id] = _encodeReceipt(true, 0, address(0));
    }

    function encodeTransactionData(
        bytes memory _dependency,
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
                keccak256(_dependency),
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

    function relay(
        bytes memory _dependency,
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
        bytes32 id = encodeTransactionData(
            _dependency,
            _to,
            _value,
            _data,
            _minGasLimit,
            _maxGasPrice,
            _salt,
            _expiration
        );
        
        if (intentReceipt[id] != bytes32(0)) {
            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }

        require(now < _expiration, "Intent is expired");
        require(tx.gasprice <= _maxGasPrice, "Gas price too high");
        require(_checkDependency(_dependency), "Dependency is not satisfied");

        address _owner = owner;
        require(msg.sender == _owner || _owner == SigUtils.ecrecover2(id, _signature), "Invalid signature");

        intentReceipt[id] = _encodeReceipt(false, block.number, msg.sender);

        require(gasleft() > _minGasLimit + EXTRA_GAS, "gasleft too low");

        // solium-disable-next-line security/no-call-value
        (success, data) = _to.call.gas(gasleft() - EXTRA_GAS).value(_value)(_data);

        emit Relayed(
            id,
            _dependency,
            _to,
            _value,
            _data,
            _salt,
            _expiration,
            success
        );
    }

    function _encodeReceipt(
        bool _canceled,
        uint256 _block,
        address _relayer
    ) internal pure returns (bytes32 _receipt) {
        assembly {
            _receipt := or(shl(255, _canceled), or(shl(160, _block), _relayer))
        }
    }
    
    function _decodeReceipt(bytes32 _receipt) internal pure returns (
        bool _canceled,
        uint256 _block,
        address _relayer
    ) {
        assembly {
            _canceled := shr(255, _receipt)
            _block := and(shr(160, _receipt), 0x7fffffffffffffffffffffff)
            _relayer := and(_receipt, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    // [160 bits (target) + n bits (data)]
    function _checkDependency(bytes memory _dependency) internal view returns (bool result) {
        if (_dependency.length == 0) {
            result = true;
        } else {
            assembly {
                let response := mload(0x40)
                let success := staticcall(
                    gas,
                    mload(add(_dependency, 20)),
                    add(52, _dependency),
                    sub(mload(_dependency), 20),
                    response,
                    32
                )

                result := and(gt(success, 0), gt(mload(response), 0))
            }
        }
    }
}
