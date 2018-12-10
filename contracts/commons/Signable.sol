pragma solidity ^0.5.0;

contract Signable {

    event AddedSigner(address signer);

    address internal signer;

    /**
      @dev Setup function sets initial storage of contract.
      @param _signer List of signer.
    */
    function initSigner(address _signer) internal {
        require(_signer != address(0), "Invalid owner address provided, signer address cannot be null");
        signer = _signer;
        emit AddedSigner(signer);
    }

    function isSigner(address _signer) internal view returns (bool) {
        return signer == _signer;
    }

}