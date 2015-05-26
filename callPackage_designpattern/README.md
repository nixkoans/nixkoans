# callPackage design pattern

This is the design pattern that's extensively used in `nixpkgs`. It is the current standard for importing packages in a repository.

## The callPackage convenience

We learnt that the inputs design pattern is great for decoupling packages from the repository, i.e. we can pass manually the inputs to the derivation. The derivation declares its inputs and the caller passes in the parameters at will.

In `nixpkgs`, we often see this pattern:

```
Some package derivation:

{ input1, input2, ... }:
...

Repository derivation:

rec {
  lib1 = import package1.nix { inherit input1 input2 ...; };
  program2 = import package1.nix { inherit inputX inputY lib1 ...; };
}
```

1. Notice the use of the `rec` (recursive) keyword.  The `rec` keyword allows us to use a package as an input. (A nix expression calling variables inside itself)

2. Also, we observe that the inputs have the same name of the attributes in the repository itself. So, how can we save ourselves some typing?

We will define a `callPackage` function which is able to do this:

```
{
    lib1 = callPackage package1.nix {};
    program2 = callPackage package2.nix { someoverride = overriddenDerivation; };
}
```

The `callPackage` function will:

* import the given expression and return a function
* determine the name of its arguments
* pass the default arguments from the repository set, and let us override those arguments when we want to

## Implementing callPackage

Nix provides a builtin function to introspect the names of the arguments of a function. In addition, for each argument, it tells whether the argument has a default value or not.  For the purpose of our `callPackage` function, we don't really care whether our argument has a default value or not. We are only interested in the argument names.

This gives us our argument names and whether the argument has a default value or not (true or false).

```
nix-repl> add = { a ? 3, b }: a + b

nix-repl> builtins.functionArgs add
{ a = true; b = false; }
```

Now, we need a set with all the values. And a way to intersect the attributes of values with the function arguments:

```
ix-repl> values = { a = 3; b = 5; c = 10; }

nix-repl> result = builtins.functionArgs add

nix-repl> result
{ a = true; b = false; }

nix-repl> builtins.intersectAttrs values result
{ a = true; b = false; }

nix-repl> builtins.intersectAttrs result values
{ a = 3; b = 5; }
```

The builtin intersectAttrs function returns a set whose names are the intersection, and the attribute values are taken from the second set.

So, the simple implementation of `callPackage` can written like this:

```
nix-repl> callPackage = set: f: f (builtins.intersectAttrs (builtins.functionArgs f) set)
```

* We define a `callPackage` variable which is a function
* `callPackage` accepts a set and it returns another function accepting another parameter. In other words, it's a function that accepts two arguments.
* The second param is the function to autocall.
* We take the argument names of the function and intersect with the set of all values.
* Finally, we call the passed function `f` with the resulting intersection.

Let's take it for a spin:

```
nix-repl> callPackage values add
8

nix-repl> with values; add { inherit a b; }
8
```

`callPackage` does exactly what `add a b` does, without needing us to specify `a` and `b`.

But we can't handle overrides yet.  So let's improve our function:

```
nix-repl> callPackage = set: f: overrides: f ((builtins.intersectAttrs (builtins.functionArgs f) set) // overrides)

nix-repl> callPackage values add { }
8

nix-repl> callPackage values add { b = 12; }
15
```

By doing a set union between our default arguments and the overriding set, we are now able to handle overrides.

## Using callPackage to simplify our nix expressions

We can now simplify `default.nix` - our repository expression

```
let
  nixpkgs = import <nixpkgs> {};
  allPkgs = nixpkgs // pkgs;
  callPackage = path: overrides:
    let f = import path;
    in f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);
  pkgs = with nixpkgs; {
    mkDerivation = import ./autotools.nix nixpkgs;
    hello = callPackage ./hello.nix { };
    graphviz = callPackage ./graphviz.nix { };
    graphvizCore = callPackage ./graphviz.nix { gdSupport = false; };
  };
in pkgs
```

* We have renamed `pkgs` to `nixpkgs`.  Our package set is now named `pkgs`.
* We need a way to pass `pkgs` to `callPackage`. Instead of returning the set of packages directly from `default.nix`, we assign it to a let variable and reuse it in `callPackage`.
* We do our `import` in our `callPackage` function beforehand so that we don't have to write `import ./somepackage.nix` when we use `callPackage`.
* Since our expressions use packages from `nixpkgs`, in `callPackage` we use `allPkgs`, which is the union of `nixpkgs` and our packages.
* We moved `mkDerivation` in `pkgs` itself, so it also gets passed automatically.
