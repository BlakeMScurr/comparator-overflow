# comparator-overflow

## What is the bug?

Comparator overflow is a common misuse of circomlib comparators.
[The `LessThan` component](https://github.com/iden3/circomlib/blob/master/circuits/comparators.circom#L89-L99) takes two *n-bit* inputs and checks returns 1 if the first is less than the second.
I.e.,
```js
component lt = Component(252); // 252 bits
lt.in[0] <== 5;
lt.in[1] <== 10;
lt.out === 1;
```

Or it returns 0 if the first number is larger:
```js
component lt = Component(252); // 252 bits
lt.in[0] <== 11;
lt.in[1] <== 10;
lt.out === 0;
```

However, if the first number is almost as large `p` (the size of the prime field), `LessThan` can unexpectedly return true.
This happens when `lt.in[0]` is close enough to `p` to "wrap around", for example, `lt.in[0] === p - 1`:

```js
component lt = Component(252); // 252 bits
lt.in[0] <== 21888242871839275222246405745257275088548364400416034343698204186575808495616; // p - 1
lt.in[1] <== 10;
lt.out === 1;
```

In particular, this happens precisely when `lt.in[0] > p - 2^n + lt.in[1]`, which (probably) does not correspond to anything meaningful for any use case.
Note that similar issues can happen when `lt.in[1]` is outside the range.

## Demonstration

To test this yourself, make sure you [install circom](https://docs.circom.io/getting-started/installation/) then run
```
npm i
./build.sh
```

If your machine is setup properly this will output `Everything went okay, circom safe`.
This shows that according to the `LessThan` comparator, `p-1 < 10`. Uncomment different lines of [main.circom](main.circom) to confirm `LessThan` works as decribed above, including verifying the flipping point.


## Fix

The simplest solution is to use [CompConstant](https://github.com/iden3/circomlib/blob/master/circuits/compconstant.circom) to verify that both inputs are in the appropriate range:
```js
template someTemplate() {
    ...
    component aInRange = Is252Bits();
    aInRange.in <== a;
    component bInRange = Is252Bits();
    bInRange.in <== lower;
    component leq = LessEqThan(252);
    leq.in[0] <== a;
    leq.in[1] <== b;
    ...
}

template Is252Bits() {
    signal input in;

    component bits = Num2Bits(254);
    bits.in <== in;

    component compare = CompConstant(2**252);
    for (var i=0; i<254; i++) {
        compare.in[i] <== bits.out[i];
    }

    compare.out === 0;
}
```

## Why does this happen?

This is the code for `LessThan`:

```js
template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n+1);

    n2b.in <== in[0]+ (1<<n) - in[1];

    out <== 1-n2b.out[n];
}
```

It's best to think of this as bitwise operation. First we get `2^n` (written as `1<<n`), which looks like `100000`, then we
add the first input, and subtract the second. If the `nth` bit has been flipped we know that second input is larger, so we should
return true, i.e., `1`, hence the bit flip on the last line.

Visually:

```
  nth-bit
  |
  v
  100
+ 011
- 001
_____
  110

The nth bit is still 1, so 011 is larger than 001
```

However, if we put an extra large number in the first input, we can wrap around and not flip the nth bit:

```
kth-bit  nth-bit
  |     |
  v     v
  000...100
+ 111...111
- 000...001
_____
  000...100

The nth bit is not flipped, so we think 100...000 < 000...001.
Note, the above sum assumes we're in a k-bit field, i.e., 111...111+000...001=0
```