pragma solidity ^0.5.0;
import "./Proxy.sol";
import "./../core/MarmoCore.sol";


contract MarmoFactory {
    
    event AddProxy(address proxy);
    
    address public marmo;
    
    constructor(address _marmo) public {
        marmo = _marmo;
    }

    function create(address _signer)
        external
        returns (Proxy proxy)
    {
        proxy = new Proxy(marmo);
        MarmoCore(address(proxy)).setup(_signer);
        emit AddProxy(address(proxy));
    }
}
