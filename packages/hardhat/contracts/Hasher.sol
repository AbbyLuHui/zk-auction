pragma solidity ^0.8.10;
import { PoseidonT3 } from "./Poseidon.sol";

contract Hasher{
  function hash_p(uint[2] memory array) public pure returns (uint256) {
    return PoseidonT3.poseidon(array);
  }
}