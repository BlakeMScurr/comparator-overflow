pragma circom 2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";

template AssertLt() {
    signal input in[2];
    component lt = LessThan(252);
    lt.in[0] <== in[0];
    lt.in[1] <== in[1];
    lt.out === 1;
}

component main = AssertLt();