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

  function buyTokens() external payable {
    uint256 amountOfTokens = msg.value * tokensPerEth;
    yourToken.transfer(msg.sender, amountOfTokens);

    emit BuyTokens(msg.sender, msg.value, amountOfTokens);
  }

  function withdraw() external onlyOwner {
     // Transfer Ether to the owner
      (bool success, ) =  msg.sender.call{value: address(this).balance}("");
      require(success, "External contract call failed.");
  }

  function sellTokens(uint256 _amount) external {
    yourToken.transferFrom(msg.sender, address(this), _amount);
    uint256 amountOfEth = _amount / tokensPerEth;
    (bool success, ) =  msg.sender.call{value: amountOfEth}("");
    require(success, "External contract call failed.");
    emit SellTokens(msg.sender, _amount, amountOfEth);
  }



}
