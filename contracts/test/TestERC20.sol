pragma solidity ^0.5.5;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract TestERC20 is ERC20 {
    event SetBalance(address _address, uint256 _balance);

    function setBalance(address _address, uint256 _target) external {
        uint256 prevBalance = balanceOf(_address);
        emit SetBalance(_address, _target);
        if (_target > prevBalance) {
            // Mint tokens
            _mint(_address, _target.sub(prevBalance));
        } else if (_target < prevBalance) {
            // Destroy tokens
            _burn(_address, prevBalance.sub(_target));
        }
    }
}
