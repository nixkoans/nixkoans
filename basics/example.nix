# Run this as
# nix-instantiate --eval example.nix
let
 # square : int -> int
 square = x: x*x;

 # sumOfSquares : int -> int -> int
 sumOfSquares = x: y: square x + square y;
in
 sumOfSquares 3 7
