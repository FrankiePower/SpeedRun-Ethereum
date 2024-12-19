// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
  event Opened(address, uint256);
  event Challenged(address);
  event Withdrawn(address, uint256);
  event Closed(address);

  mapping(address => uint256) balances;
  mapping(address => uint256) canCloseAt;

  function fundChannel() public payable {
    if(balances[msg.sender] != 0) revert  ("Channel already Opened!");
    if(canCloseAt[msg.sender] != 0) revert("Channel Closed!");
    balances[msg.sender] += msg.value;
    emit Opened(msg.sender, msg.value);
  }

  function timeLeft(address channel) public view returns (uint256) {
    if (canCloseAt[channel] == 0 || canCloseAt[channel] < block.timestamp) {
      return 0;
    }

    return canCloseAt[channel] - block.timestamp;
  }

  function withdrawEarnings(Voucher calldata voucher) public onlyOwner {
    // like the off-chain code, signatures are applied to the hash of the data
    // instead of the raw data itself
    bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));

    // The prefix string here is part of a convention used in ethereum for signing
    // and verification of off-chain messages. The trailing 32 refers to the 32 byte
    // length of the attached hash message.
    //
    // There are seemingly extra steps here compared to what was done in the off-chain
    // `reimburseService` and `processVoucher`. Note that those ethers signing and verification
    // functions do the same under the hood.
    //
    // see https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
    bytes memory prefixed = abi.encodePacked("\x19Ethereum Signed Message:\n32", hashed);
    bytes32 prefixedHashed = keccak256(prefixed);

    address signer = ecrecover(prefixedHashed, voucher.sig.v, voucher.sig.r, voucher.sig.s);

    require(
      signer != address(0) && balances[signer] > voucher.updatedBalance,
      "withdrawEarnings: invalid signature"
    );

    uint256 payment = balances[signer] - voucher.updatedBalance;
    balances[signer] -= voucher.updatedBalance;

    (bool sent,) = payable(owner()).call{value: payment}("");
    require(sent, "withdrawEarnings: revert in transferring eth to owner!");
    emit Withdrawn(signer, payment);
  }

  function challengeChannel() public {
    require(balances[msg.sender] > 0, "ChallengeChannel: no balance to challenge");
    
    canCloseAt[msg.sender] = block.timestamp + 30 seconds;
    
    emit Challenged(msg.sender);}

    function defundChannel()  public{
      require(canCloseAt[msg.sender] != 0 && canCloseAt[msg.sender] < block.timestamp, "defundChannel: no challenge to defund");

      uint256 payment = balances[msg.sender];
      balances[msg.sender] = 0;

      (bool sent,) = msg.sender.call{value: payment}("");
      require(sent, "defundChannel: revert in transferring eth to you!");
      
      emit Closed(msg.sender);
    }

  struct Voucher {
    uint256 updatedBalance;
    Signature sig;
  }
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
}
