include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/mux1.circom";
include "../../node_modules/circomlib/circuits/comparators.circom"

template PoseidonHashT3() {
    var nInputs = 2;
    signal input inputs[nInputs];
    signal output out;

    component hasher = Poseidon(nInputs);
    for (var i = 0; i < nInputs; i ++) {
        hasher.inputs[i] <== inputs[i];
    }
    out <== hasher.out;
}

// Computes PoseidonHash([left, right])
template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = PoseidonHashT3();
    hasher.inputs[0] <== left;
    hasher.inputs[1] <== right;
    hash <== hasher.out;
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0
    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}


template BidVerifier(levels) {
    signal input leaf;
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    
    signal private input account;
    signal private input value;
    signal private input bid;

    // Merkle tree inclusion check
    component selectors[levels];
    component hashers[levels];
    signal output hashP;
    signal output outValid;
    signal output finalBid;
    
    // TODO: check validity against contracts e.g. root

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].out[0];
        hashers[i].right <== selectors[i].out[1];
    }

    root === hashers[levels - 1].hash;

    // Bid validity check
    component hasher = PoseidonHashT3();
    hasher.inputs[0] <== account;
    hasher.inputs[1] <== value;
    hashP <== hasher.out;
    hashP === leaf;

    component greater = LessThan(11);
    greater.in[0] <== value;
    greater.in[1] <== bid;

    outValid <== greater.out; 
    finalBid <== bid;
}

component main = BidVerifier(16);
