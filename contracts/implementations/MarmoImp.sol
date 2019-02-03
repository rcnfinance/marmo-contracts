pragma solidity ^0.5.0;


contract MarmoImp {
    uint256 private constant EXTRA_GAS = 21000;

    event Receipt(
        bytes32 indexed _id,
        bool _success,
        bytes _result
    );

    function() external payable {
        (
            bytes32 id,
            bytes memory data
        ) = abi.decode(
            msg.data, (
                bytes32,
                bytes
            )
        );

        bytes memory dependency;
        address to;
        uint256 value;
        uint256 minGasLimit;
        uint256 maxGasPrice;
        uint256 expiration;

        (
            dependency,
            to,
            value,
            data,
            minGasLimit,
            maxGasPrice,
            expiration
        ) = abi.decode(
            data, (
                bytes,
                address,
                uint256,
                bytes,
                uint256,
                uint256,
                uint256
            )
        );

        require(now < expiration, "Intent is expired");
        require(tx.gasprice < maxGasPrice, "Gas price too high");
        require(_checkDependency(dependency), "Dependency is not satisfied");
        require(gasleft() - EXTRA_GAS > minGasLimit, "gasleft too low");

        (bool success, bytes memory result) = to.call.gas(gasleft() - EXTRA_GAS).value(value)(data);

        emit Receipt(
            id,
            success,
            result
        );
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
