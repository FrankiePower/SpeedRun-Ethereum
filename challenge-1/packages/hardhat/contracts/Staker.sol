// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

  /**
   * @title Staker
   * @dev A contract that allows users to stake their ether and, if the threshold is met,
   * sends the ether to an external contract and calls its complete() function.
   * If the threshold is not met, users can withdraw their ether.
   */

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  bool public openForWithdraw;

  mapping(address => uint256) public balances;

  uint256 public immutable threshold = 1 ether;

  uint public immutable minStake = 0.001 ether;

  uint256 public immutable deadline = block.timestamp + 72 hours;

  event Stake(address indexed from, uint256 amount);

  event Withdraw(address indexed from, uint256 amount);

  // Custom Errors
  error DeadlineNotReached();
  error ThresholdNotMet();
  error ZeroAddress();
  error StakeAmountTooLow();
  error YouAreNotAStaker();




  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

    modifier notCompleted {
    require(exampleExternalContract.completed() == false, "Staking has already been completed.");
    _;
  }

    function stake() public payable{
      if (msg.sender == address(0)) revert ZeroAddress();
      if (msg.value < minStake) revert StakeAmountTooLow();
      
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);
  }

function execute() public notCompleted {
    require(block.timestamp >= deadline, "Deadline not reached.");
    
    // Remove redundant check since we already confirmed timestamp >= deadline
    if (address(this).balance >= threshold) {
        (bool success, ) = address(exampleExternalContract).call{value: address(this).balance}(
            abi.encodeWithSignature("complete()")
        );
        require(success, "External contract call failed.");
    } else {
        openForWithdraw = true;
        // Don't use revert here as it rolls back state changes
        emit Withdraw(msg.sender, address(this).balance); // Add an event to notify users
    }
}
 
function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) return 0;
    return deadline - block.timestamp;
}

function withdraw() external notCompleted{
  require(openForWithdraw == true, "Withdrawals are not open.");
  require(balances[msg.sender] > 0, "You did not stake.");

  uint256 amountToWithdraw = balances[msg.sender];
  balances[msg.sender] = 0; // Reset the user's balance before transferring 

  (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
  require(success, "External contract call failed.");
  openForWithdraw = false;
  emit Withdraw(msg.sender, amountToWithdraw);
}
  receive() external payable{
    stake();
  }

}
