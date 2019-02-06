pragma solidity ^0.5.0;

import "../MarmoStork.sol";

/* solium-disable-next-line */
contract MarmoStorkAuto is MarmoStork(abi.encodePacked(new Marmo())) { }
