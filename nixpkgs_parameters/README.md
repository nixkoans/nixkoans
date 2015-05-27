# nixpkgs parameters

`nixpkgs` has its own manual here - <a href="http://nixos.org/nixpkgs/manual/">http://nixos.org/nixpkgs/manual/</a>.

`nix` language is used to create `nixpkgs` but the two are not the same thing.

## General structure of nixpkgs

In our custom repository `mypkgs`, we created a `default.nix` which composed the expressions of the various packages.

`nixpkgs` has its own `default.nix` which is the one being loaded when referring to `<nixpkgs>`. See <a href="https://github.com/NixOS/nixpkgs/blob/master/default.nix">https://github.com/NixOS/nixpkgs/blob/master/default.nix</a>

All it does it to check for the minimal version of nix required and if satisfied, imports the `./pkgs/top-level/all-packages.nix` expression - <a href="https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/all-packages.nix">https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/all-packages.nix</a>.

`all-packages.nix` composes all the packages and accepts a couple of parameters:

* system: defaults to the current system
* config: defaults to null
* others...

The `system` parameter specifies the system for which the packages will be built. We can use it to install i686 packages on amd64 machines.

The `config` parameter is a simple attribute set. Packages can read some of its values and change the behavior of some derivations.

## The system parameter

This parameter is present in many nix expressions. Whenever we want to import pkgs, we will usually also pass through the value of the system to the imported pkgs. E.g. in an example `release.nix`:

```
{ system ? builtins.currentSystem }:

let pkgs = import <nixpkgs> { inherit system; };
...
```

How do we do that? How do we build the derivation for i686-linux instead of the default x86_84-linux?

Here's an example:

```
$ nix-build -A psmisc --argstr system i686-linux
```

This concept is similar to the multi-arch approach in Debian.

This setup for cross compiling is available in `nixpkgs`.

## The config parameter

`nixpkgs`'s `all-packages.nix` accepts the `config` parameter.  If it is null, it will read the `NIXPKGS_CONFIG` environment variable.  If not specified, `nixpkgs` will use `$HOME/.nixpkgs/config.nix`.

After determining which `config.nix` to use, it will be imported as a nix expression and that will be the value of `config`.

The `config` is available in the resulting repository:

```
nix-repl> pkgs = import <nixpkgs> {}

nix-repl> pkgs.config
{ packageOverrides = «lambda»; vim = { ... }; }
```

As you can see, I have a custom `.nixpkgs/config.nix` and it shows the value of my set in `config.nix`.

Some examples for the use of `config` are:

* Using `config.allowUnfree` as an attribute that forbids building packages that have an unfree license by default.
* `config.pulseaudio` setting tells nix whether to build packages with `pulseaudio` support or not where applicable and when the derivation obeys the setting/ support or not where applicable and when the derivation obeys the setting.

## About .nix functions

A .nix file contains a nix expression.  Thus, it can also be a function.

`nix-build` expects the expression to return a derivation. Therefore, it's natural to return straight a derivation from a .nix file.

It is common for the .nix file to accept some parameters in order to customize the returned derivation.

Nix handles our .nix file in this manner:

* If the expression is a derivation, build it
* If the expression is a function, call it and build the resulting derivation

We can `nix-build` a .nix file that contains:

```
{ pkgs ? import <nixpkgs> {} }:

pkgs.psmisc
```

Nix is able to call this function in our .nix file because the `pkgs` parameter has a default value.  This allows us to pass a different value for `pkgs` using the `--arg` option.

Will it work if we have a function returning a function that returns a derivation? No, Nix only calls the function it encounters once. It is not recursive.

## nixpkgs

The `<nixpkgs>` repository is nothing more than a function that accepts some parameters and returns the set of all packages.

Due to the lazy nature of nix language, only the accessed derivations will be built.
