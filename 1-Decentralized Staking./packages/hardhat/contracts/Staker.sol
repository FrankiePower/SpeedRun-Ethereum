// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping (address => uint256) public balances;
  uint256 public constant minStake = 0.001 ether;
  uint256 public constant threshold = 1 ether;
  uint public immutable deadline = block.timestamp + 72 hours;
  bool public openForWithdrawal;

  event Stake(address indexed from, uint256 amount);
  event Withdraw(address indexed from, uint256 amount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted{
    require(exampleExternalContract.completed() == false, "Staking has already been completed.");
    _;
  }

  function stake() public payable {
    require(msg.sender != address(0), "Zero address");
    require(msg.value >= minStake, "Stake amount too low.");
    balances [msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute () public notCompleted {
    require(block.timestamp > deadline, "Deadline not reached.");
    
    if(address(this).balance >= threshold) {
      (bool success,) = address(exampleExternalContract).call{value:address(this).balance}(
        abi.encodeWithSignature("complete()")
      );
      require(success, "External contract call failed.");
    } else {
      openForWithdrawal = true;
      emit Withdraw(msg.sender, address(this).balance);
    }
  }
  
  function withdraw() external notCompleted {
    require(openForWithdrawal == true, "Withdrawals are not available.");
    require(balances[msg.sender] > 0, "You did not stake Chief!");
    uint256 withdrawalAmount = balances[msg.sender];
    balances[msg.sender] = 0;

    (bool success,) = msg.sender.call{value: withdrawalAmount}("");
    require(success, "External contract call failed.");
    openForWithdrawal = false;
    emit Withdraw(msg.sender, withdrawalAmount);
  }


  function timeLeft() public view returns(uint256){
    if(block.timestamp > deadline) return 0;
    return(deadline - block.timestamp);
  }

  receive () external payable {
    stake();
  }

}
