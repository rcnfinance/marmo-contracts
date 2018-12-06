pragma solidity ^0.5.0;

contract Marmo {
    address public signer;

    mapping(bytes32 => address) public relayerOf;
    mapping(bytes32 => bool) public isCanceled;

    event Relayed(
        bytes32 _id,
        bytes32 _parent,
        address _to,
        uint256 _value,
        bytes _data,
        bytes32 _salt,
        address _relayer,
        bool _success,
        bytes _result
    );

    event Canceled(bytes32 _id);
    event SetSigner(address _prev, address _signer);

    function calculateId(
        bytes32 _parent,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes32 _salt
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                this,
                _parent,
                _to,
                _value,
                _data,
                _salt
            )
        );
    }

    function sendTransaction(
        bytes32 _parent,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes32 _salt,
        bytes calldata _sig
    ) external returns (bool success, bytes memory result) {
        bytes32 id = calculateId(_parent, _to, _value, _data, _salt);

        require(!isCanceled[id], "Transaction is canceled");
        require(relayerOf[id] == address(0), "Transaction already relayed");
        require(_parent == 0x0 || relayerOf[_parent] != address(0), "Parent relay not found");
        require(_ecrecovery(id, _sig) == signer, "Signature not valid");

        (success, result) = _to.call.value(_value)(_data);

        emit Relayed(
            id,
            _parent,
            _to,
            _value,
            _data,
            _salt,
            msg.sender,
            success,
            result
        );

        relayerOf[id] = msg.sender;
    }

    function cancel(bytes32 _id) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");
        require(relayerOf[_id] == address(0), "Transaction was already relayed");
        isCanceled[_id] = true;
    }

    function setSigner(address _signer) external {
        require(msg.sender == address(this) || signer == address(0), "Only wallet can change signer");
        emit SetSigner(signer, _signer);
        signer = _signer;
    }

    function _ecrecovery(bytes32 _hash, bytes memory _sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := and(mload(add(_sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(_hash, v, r, s);
    }
    
    function() external payable {}
}
