//pragma solidity >=0.6.0 <0.9.0;
pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./hashVerifier.sol";
import "./MerkleTreeWithHistory.sol";
// import {IHasher} from "./Hasher.sol";
//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


contract YourContract is Verifier, MerkleTreeWithHistory {

  event SetPurpose(address sender, string purpose);

  string public purpose = "Building Unstoppable Apps";
  
  uint256 public verifiedBid;

  constructor(uint32 _levels, address _hasher) MerkleTreeWithHistory(_levels, _hasher){
  }

  function setPurpose(string memory newPurpose) public {
    purpose = newPurpose;
    // console.log(msg.sender,"set purpose to",purpose);
    emit SetPurpose(msg.sender, purpose);
  }


  function commit(bytes32 _commitment) public {
    uint32 insertedIndex = _insert(_commitment);
  }

  function bid(
          uint[2] memory a,
          uint[2][2] memory b,
          uint[2] memory c,
          uint[36] memory input
      ) public {
      require(verifyProof(a, b, c, input), "Invalid Proof");
      verifiedBid = input[0];

  }

} 

