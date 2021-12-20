const { ethers } = require("hardhat");
const { use, expect, assert } = require("chai");
const { solidity } = require("ethereum-waffle");
// const { MerkleTree } = require('./merkleTree');
const MerkleTree = require('fixed-merkle-tree')
const snarkjs = require('snarkjs');

use(solidity);

function toFixedHex(number, length = 32) {
  let str = BigInt(number).toString(16)
  while (str.length < length * 2) str = '0' + str
  str = '0x' + str
  return str
}

describe("My Dapp", function () {
  let myContract;
  let merkleTreeWithHistory; 
  let levels = 16;
  let Poseidon;
  let hasherInstance;



  describe("YourContract", function () {
    it("Should deploy YourContract", async function () {
      const PoseidonContract = await ethers.getContractFactory("PoseidonT3");
      Poseidon = await PoseidonContract.deploy();
      const hasherContract = await ethers.getContractFactory("Hasher", {
        libraries: {
            PoseidonT3: Poseidon.address,
        }
      });
      hasherInstance = await hasherContract.deploy();
      const YourContract = await ethers.getContractFactory("YourContract", {
        libraries: {
          PoseidonT3: Poseidon.address,
        }
      });
      myContract = await YourContract.deploy(levels, hasherInstance.address);
    });

    describe("setPurpose()", function () {
      it("Should be able to set a new purpose", async function () {
        const newPurpose = "Test Purpose";

        await myContract.setPurpose(newPurpose);
        expect(await myContract.purpose()).to.equal(newPurpose);
      });
    });

    describe('#constructor', () => {
        it('should initialize', async () => {
          const zeroValue = await myContract.ZERO_VALUE()
          const firstSubtree = await myContract.filledSubtrees(0)
          assert.equal(firstSubtree, toFixedHex(zeroValue));
          const firstZero = await myContract.zeros(0);
          assert.equal(firstZero, toFixedHex(zeroValue))
        })

        it('should initialize tree', async () => {
            tree = new MerkleTree(16, [])
        })
      })

    describe('#hash', () => {
        it('test hash function', async () => {
            let hash = await myContract.hashLeftRight(toFixedHex(1), toFixedHex(2));
            console.log(hash);
        })
    })


    describe('#insert', () => {
      it('should insert', async () => {
        let rootFromContract
  
        for (let i = 1; i < 11; i++) {
          await myContract.commit(toFixedHex(i))
          await tree.insert(i)
          rootFromContract = await myContract.getLastRoot()
          console.log(rootFromContract.toString())
          console.log(toFixedHex(tree.root()))
          assert.equal(toFixedHex(tree.root()), rootFromContract.toString())
        }
      })


      it('should reject if tree is full', async () => {
        const levels = 6
        const MerkleContract = await ethers.getContractFactory("YourContract", {
            libraries: {
              PoseidonT3: Poseidon.address,
            }
        });
        merkleTreeWithHistory = await MerkleContract.deploy(levels, hasherInstance.address);
  
        for (let i = 0; i < 2 ** levels; i++) {
          await merkleTreeWithHistory.commit(toFixedHex(i + 42))
        }
        // let error = await merkleTreeWithHistory.commit(toFixedHex(1337)).rejected
        // error = await merkleTreeWithHistory.commit(toFixedHex(1)).rejected
        // error.reason.should.be.equal('Merkle tree is full. No more leaves can be added')
      })
    });

  })
});