# Packaging a C program

In nix-repl, we can run:

```
nix-repl> :l <nixpkgs>

nix-repl> simple = derivation {
    name = "simple";
    builder = "${bash}/bin/bash";
    args = [ ./simple_builder.sh ];
    clang = clang;
    coreutils = coreutils;
    src = ./simple.c;
    system = builtins.currentSystem;
}

nix-repl> :b simple
```

OR

Write a `simple.nix` file:

```
with (import <nixpkgs> {});

derivation {
  name = "simple";
  builder = "${bash}/bin/bash";
  args = [ ./simple_builder.sh ];
  inherit clang coreutils;
  src = ./simple.c;
  system = builtins.currentSystem;
}
```

and in our normal shell, we can run:

```
$ nix-build simple.nix
```

If we use `nix-build`, `nix-build` does two main jobs:

* `nix-instantiate`: parse `simple.nix` and return the `.drv` file relavtive to the parsed derivation set.
* `nix-store -r`: realise the `.drv` and actually build the derivation.

Finally, once done, make a symlink to the binary in `out`.

Here in this example, we have a new `inherit` keyword. `inherit` expands like this - `inherit foo bar` to `foo = foo; bar = bar;`. `inherit` is a convenience keyword inside sets to save us from typing the same name twice (once for the attribute name and onc for the variable in the scope).
