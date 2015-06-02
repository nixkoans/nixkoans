# The override design pattern

So we have learnt about the *inputs design pattern* and the *callPackage* function that simplifies our nix repository. We will now learn about the `override` design pattern which is used to compose functions to achieve different results.

## Composability

By calling multiple functions, we can achieve the desired modifications on our data structure.

Let's say we have an initial derivation `drv` and we want it to become a `drv` with debugging information and apply some custom patches:

```
debugVersion (applyPatches [ ./patch1.patch ./patch2.patch ] drv)
```

The final result will still be the original derivation plus some changes.

## Override

In our original `graphviz` example, we have:

```
graphviz = import ./graphviz.nix { inherit mkDerivation gd fontconfig libjpeg bzip2; };
```

If we want to produce a derivation of `graphviz` with a customized `gd` version, we would have to repeat most of the above plus specifying an alternative `gd`:

```
mygraphviz = import ./graphviz.nix {
  inherit mkDerivation fontconfig libjpeg bzip2;
  gd = customgd;
};
```

If we use `callPackage`, it will be easier:

```
mygraphviz = callPackage ./graphviz.nix { gd = customgd; };
```

but we would still have diverged from the original graphviz from the repository.

So, to avoid having to specify the nix expression all over again, we will reuse, our original `graphviz` attribute in the repository and add our overrides like this:

```
mygraphviz = graphviz.override { gd = customgd; };
```

`override` is not a method like what we are used to in OO languages.  Nix is a functional language so `.override` is simply an attribute of a set.

## How is override implemented?

Let's create a function `makeOverridable` that takes a function and a set of original arguments to be passed to the function.

In `lib.nix`:

```
{
    makeOverridable = f: origArgs:
        let
            origRes = f origArgs;
        in
            origRes // { override = newArgs: f (origArgs // newArgs); };
}
```

`makeOverridable` takes a function and a set of original arguments and it returns the original returned set, plus a new `override` attribute.  This `override` attribute is a function taking a set of new arguments and returns the result of the original function called with the original arguments unified with new arguments.

In nix-repl:

```
nix-repl> :l lib.nix
Added 1 variables.

nix-repl> f = { a, b }: { result = a + b; }

nix-repl> f { a = 3; b = 5; }
{ result = 8; }

nix-repl> res = makeOverridable f { a = 3; b = 5; }

nix-repl> res
{ override = «lambda»; result = 8; }

nix-repl> res.override { a = 10; }
{ result = 15; }
```

The variable `res` is the result of the function call without any override. It's easy to see in the definition of `makeOverridable`. In addition, the new override attribute is a function.

Calling `.override` with a set will invoke the original function with the overrides, as expected. But we cannot override again because the returned set with result 15 does not have an override attribute.  This is bad because it breaks further compositions.

To solve this problem, we improve our `makeOverridable` function from its original form:

```
{
    makeOverridable = f: origArgs:
        let
            origRes = f origArgs;
        in
            origRes // { override = newArgs: f (origArgs // newArgs); };
}
```

to this:


```
rec {
  makeOverridable = f: origArgs:
    let
      origRes = f origArgs;
    in
      origRes // { override = newArgs: makeOverridable f (origArgs // newArgs); };
}
```

which is a recursive call to `makeOverridable`.

Now we can keep overriding:

```
nix-repl> :l lib.nix
Added 1 variables.

nix-repl> f = { a, b }: { result = a + b; }

nix-repl> res = makeOverridable f { a = 3; b = 5; }

nix-repl> res2 = res.override { a = 10; }

nix-repl> res2
{ override = «lambda»; result = 15; }

nix-repl> res2.override { b = 20; }
{ override = «lambda»; result = 30; }
```

The "override" pattern simplifies the way we customize packages starting from an existing set of packages.  This opens a world new world of possibilities about using a central repository like `nixpkgs` and defining overrides on our local machine without even modifying the original package.

Now we can use this `override` attribute to test a custom `graphviz` in an isolated nix-shell environment at all.  e.g.:

```
debugVersion (graphviz.override { gd = customgd; })
```
