pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);


  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    uint256 amountOfETH = msg.value;
    uint256 amountOfTokens = amountOfETH * tokensPerEth;

    yourToken.transfer(msg.sender, amountOfTokens);

    emit BuyTokens(msg.sender, amountOfETH, amountOfTokens);
  }

  function withdraw() external onlyOwner {
    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success, "External contract call failed.");
    
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) public {
    yourToken.transferFrom(msg.sender, address(this), _amount);
    uint256 amountOfETH = _amount / tokensPerEth;
    (bool success,) = msg.sender.call{value: amountOfETH}("");
    require(success, "External contract call failed.");
    emit SellTokens(msg.sender, _amount, amountOfETH);
  }
}
