pragma solidity ^0.5.5;

import "../MarmoStork.sol";

/* solium-disable-next-line */
// Easy deploy of MarmoStork
// create MarmoSource and deploy MarmoStork using that source
contract MarmoStorkAuto is MarmoStork(address(new Marmo())) { }
