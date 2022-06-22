pragma circom 2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";

template AssertLt() {
    component lt = LessThan(252);
    // Normal cases
    // lt.in[0] <== 1; // Succeeds becuase 1 < 10
    // lt.in[0] <== 11; // Fails because 11 !< 10

    // Simplest overflow example
    lt.in[0] <== 21888242871839275222246405745257275088548364400416034343698204186575808495617; // p-1 unexpectedly succeeds due to overflow

    // The tipping point
    // lt.in[0] <== 14651237294507013008273219182214280847718990358813499091232105186081237893130; // p-2^252+10-1    fails as usual
    // lt.in[0] <== 14651237294507013008273219182214280847718990358813499091232105186081237893131; // p-2^252+10    succeeds unexpectedly

    lt.in[1] <== 10;
    lt.out === 1;
}

component main = AssertLt();