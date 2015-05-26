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


