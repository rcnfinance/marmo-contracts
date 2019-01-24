pragma solidity ^0.5.0;

import "../Marmo.sol";

contract DepsUtils {
    function multipleDeps(Marmo[] calldata _wallets, bytes32[] calldata _ids) external view returns (bool) {
        uint256 size = _wallets.length;

        require(
            size == _ids.length,
            "_wallets and _ids should have equal length"
        );

        for (uint256 i = 0; i < size; i++) {
            if (_wallets[i].relayedBy(_ids[i]) == address(0)) {
                return false;
            }
        }

        return true;
    }
}
