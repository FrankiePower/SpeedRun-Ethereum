pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YourToken is ERC20 {

  address public owner ;
  constructor() ERC20("Super", "SUP") {
    owner = msg.sender;
    _mint( owner, 10000 * 10 ** 18);
  }

  function mint(uint _amount) external {
        _mint(msg.sender,_amount * 1e18);
    }
}
