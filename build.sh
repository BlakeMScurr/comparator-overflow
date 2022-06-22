#!/usr/bin/env bash

mkdir -p build

# compile circom 
circom main.circom --r1cs --wasm --sym --c -o build

# create witness
node build/main_js/generate_witness.js build/main_js/main.wasm input.json build/witness.wtns