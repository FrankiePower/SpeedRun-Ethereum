pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract YourToken is ERC20 {

address public owner ;
  constructor() ERC20("Gold", "GLD") {
    owner = msg.sender;   
    _mint(owner,2000 * 10 ** 18 );
    
  }

   function mint(uint _amount) external {
        _mint(msg.sender,_amount * 1e18);
    }
}
