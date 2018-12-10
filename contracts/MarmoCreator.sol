pragma solidity ^0.5.0;

import "./Marmo.sol";
import "./commons/Proxy.sol"; 

contract MarmoFactory {
    // Compiled Proxy.sol
    bytes public constant PROXY_BYTECODE = hex"6080604052348015600f57600080fd5b5060838061001e6000396000f3fe60806040527f7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c280548015156034576000358255005b3660008037600080366000845af43d6000803e8080156052573d6000f35b3d6000fdfea165627a7a72305820cb39008bb4c53fbfeb0e7d4b29bc7c146e41d74a283816b04727025b0d2051e00029";
    bytes32 public constant CODE_HASH = keccak256(PROXY_BYTECODE);

    address public marmoSource;

    constructor(address _marmo) public {
        marmoSource = _marmo;
    }
    
    function marmoOf(address _signer) external view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        bytes32(uint256(_signer)),
                        CODE_HASH
                    )
                )
            )
        );
    }

    function reveal(address _signer) external returns (Proxy p) {
        bytes memory proxyCode = PROXY_BYTECODE;

        assembly {
            let nonce := mload(0x40)
            mstore(nonce, _signer)
            mstore(0x40, add(nonce, 0x20))
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }

        (bool success, ) = address(p).call(abi.encode(marmoSource));
        require(success, "Setup failed");
        Marmo(address(p)).init(_signer);
    }
}
