pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract YourToken is ERC20 {

address public owner = 0x0752f523512Ad24E82739D3434C0710A4cA5058f;
  constructor() ERC20("Gold", "GLD") {
   
    _mint(owner,1000 * 10 ** 18 );
    
  }

   function mint(uint _amount) external {
        _mint(msg.sender,_amount * 1e18);
    }
}
