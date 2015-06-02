# nixpkgs, overriding packages

There are two ways to derive custom versions of packages in `nixpkgs`.

The first way is by using `.nixpkgs/config.nix` (the `config` parameter).  This is the second way - overriding packages.

The special attribute is part of `config` and is accessed via `config.packageOverrides`.  Overriding packages in a set with fixed point can be considered another design pattern in nixpkgs.

## Overriding the package

We have learnt about the `override` attribute in a previous tutorial.

For example, like our `graphviz` example but now, using `<nixpkgs>` instead of `<mypkgs>`:

```
nix-repl> :l <nixpkgs>
Added 4543 variables.

nix-repl> :b graphviz.override { xlib = null; }
```

This will build us `graphviz` without X support.

However, let's say a package P depends on graphviz, how do we make P depend on the new graphviz without X support?

In an imperative world, we will do something like this:

```
pkgs = import <nixpkgs> {};
pkgs.graphviz = pkgs.graphviz.override { xlib = null; };
build(pkgs.P);
```

Given that `pkgs.P` depends on pkgs.graphviz, it is easy to build P with the replaced `graphviz`.  On a pure function language, it is not so easy because you can assign to variables only once.

## Fixed point

The fixed point with lazy evaluation is crippling but a necessary technique in a language like Nix. It lets us achieve something similar to what we would do imperatively.

```
# Take a function and evaluate it with its own returned value.
fixed = f:
    let result = f result;
    in result
```

This is a function that accepts a function `f`, calls `f result` on the result just returned by `f result` and returns it.  In other words, it's `f(f(f(...)))`, an infinite loop.

But since Nix has lazy evaluation, it isn't an infinite loop because the call is done only when needed.

```
nix-repl> fix = f: let result = f result; in result

nix-repl> pkgs = self: { a = 3; b = 4; c = self.a + self.b; }

nix-repl> fix pkgs
{ a = 3; b = 4; c = 7; }

nix-repl>
```

Without using the `rec` keyword, we are able to refer to `a` and `b` of the same set.

1. First `pkgs` gets called with an unevaluated think (pkgs (pkgs (pkgs ...))).
2. To set the value of `c` then `self.a` and `self.b` are evaluated.
3. The `pkgs` function gets called again to get the value of `a` and `b`.

The important point is that `c` is not needed to be evaluated in the inner call, thus it doesn't go in an infinite loop.

More details here - <a href="http://r6.ca/blog/20140422T142911Z.html">http://r6.ca/blog/20140422T142911Z.html</a>.

## Overriding a set with fixed point

Given that `self.a` and `self.b` refer to the passed set and not to the literal set in the function, we are able to override both `a` and `b` and get a new value for `c`.

```
nix-repl> overrides = { a = 1; b = 2; }

nix-repl> let newpkgs = pkgs (newpkgs // overrides); in newpkgs
{ a = 3; b = 4; c = 3; }

nix-repl> let newpkgs = pkgs (newpkgs // overrides); in newpkgs // overrides
{ a = 1; b = 2; c = 3; }
```

In the first case, we computed `pkgs` with the `overrides`.

In the second case, we also included the overridden attributes in the result.

## So, how do we apply this technique to nixpkgs?

`nixpkgs` provides us with the `config.packageOverrides` attribute. `nixpkgs` returns a fixed point of the package set, and `packageOverrides` is used to inject the `overrides`.

If we write a `config.nix` like this:

```
{
    packageOverrides = pkgs: {
        graphviz = pkgs.graphviz.override { xlibs = null; };
    };
}
```

Now when we build other packages from `pkgs`, like this:

```
nix-repl> pkgs = import <nixpkgs> { config = import ./config.nix; }

nix-repl> :b pkgs.ascii.docFull
```

In `nixpkgs`, we can see the use of `packageOverrides` to pass in the `config` in this manner. In `nixpkgs`, `pkgs.asciidocFull` is a derivation that has `graphviz` input while `pkgs.asciidoc` is the lighter version that does not use `graphviz` at all.


If we place our `packageOverrides` declaration in `$HOME/.nixpkgs/config.nix`, `nixpkgs` automatically imports that `config.nix`

In essence, this is what it means to use a fixed point for overriding packages in a package set. It is a common Nix design pattern.

In other package managers, we customize required feature set/library dependencies and replace the old version completely and applications will use the upgraded version.

With Nix, we are precise about specific versions of libraries we want to use and hence we have to recompile `asciidoc` to use the new graphviz library.  Th newly built asciidoc will depend on the new graphviz and the old asciidoc will keep using the old graphviz undisturbed.
