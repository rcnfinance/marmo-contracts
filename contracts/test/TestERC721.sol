pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";


contract TestERC721 is ERC721Full {
    constructor() public ERC721Full("Test ERC721", "T721") {}

    function mint(address _to, uint256 _id) external {
        _mint(_to, _id);
    }
}
