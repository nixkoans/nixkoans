# Inputs Design Pattern

We have packaged an hello world program so far. What if we want to create a repository of multiple packages?

## Repositories in Nix

Nix is a tool for build and deployment (installation).  Nix does not enforce any particular repository format. A repository of packages is the main usage for Nix but is not the only possibility.  A repository of packages is a consequence of us organizing packages.

Nix is a language and we can choose the format of our own repository and so there is no preset directory structure or preset packaging policy.

The `nixpkgs` repository has a certain structure which is the result of evolution and community conventions over time.  Because there are some packaging tasks which are repeated again and again except for different software, these become identified patterns and gets reused when the community thinks that it is a good way to package the software.

## The single repository pattern

Before introducing the "inputs" pattern, let's talk about the "single repository" pattern.

Systems like Debian scatter packages in several small repositories.  From a package maintainer perspective, this actually makes it hard to track interdependent changes and to contribute to new packages.

Systems like Gentoo, on the other hand, put package descriptions all in one single repository.

Nix adopts a pattern much like Gentoo's.  The nix reference for packages is `nixpkgs`, a single repository of all descriptions of all packages.

The natural implementation in Nix is to create a top-level Nix expression, and one expression for each package.  The top-level expression imports and combines all expressions in a giant attribute set with `name -> package` pairs.  Fortunately, because Nix is a lazy language (like Haskell), it evaluates only what's needed so memory requirements are minimal for this giant attribute set.

## Packaging graphviz

Grab the graphviz source from <a href="http://www.graphviz.org/pub/graphviz/stable/SOURCES/graphviz-2.38.0.tar.gz">http://www.graphviz.org/pub/graphviz/stable/SOURCES/graphviz-2.38.0.tar.gz</a>.

Referencing:

* graphviz.nix; and
* autotools.nix (which is re-used from our generic builder for hello.nix)
* builder.sh

Now, let's use our installed graphviz utilities to generate a png file.

```
$ echo 'graph test { a -- b }' | ./result/bin/dot -Tpng -o test.png
Format: "png" not recognized. Use one of: canon cmap cmapx cmapx_np dot eps fig gv imap imap_np ismap pic plain plain-ext pov ps ps2 svg tk vml xdot xdot1.2 xdot1.4
```

Aha, it works but our installed `graphviz` does not know how to handle png. It only supports the file formats indicated in its error message above since we have installed `graphviz` as-is.  In order to configure `graphviz` with `png support`, we need to compile a second package - a dependency that `graphviz` relies on to provide png file format support.

`libgd` is one such dependency which can be used by `graphviz` as a plugin to output png files.

## gcc and ld wrappers

The `gd`, `jpeg`, `fontconfig` and `bzip2` libraries (dependencies of `gd`) don't use `pkg-config` to specify which flags to pass to the compiler. Since there's no global location for libraries, we need to tell `gcc` and `ld` where to find includes and libs.

The `nixpkgs` provides `gcc` and `binutils` and we are using them for our packaging. Not only, it also provides wrappers for them which allow passing extra arguments to `gcc` and `ld`, bypassing the project build systems:

* `NIX_CFLAGS_COMPILE`: extra flags to gcc at compile time
* `NIX_LDFLAGS`: extra flags to ld

Therefore, we employ the same technique we did for `PATH` - automatically filling the variables from `buildInputs`.  This is the relevant snippet:

```
for p in $baseInputs $buildInputs; do
  if [ -d $p/bin ]; then
    export PATH="$p/bin${PATH:+:}$PATH"
  fi
  if [ -d $p/include ]; then
    export NIX_CFLAGS_COMPILE="-I $p/include${NIX_CFLAGS_COMPILE:+ }$NIX_CFLAGS_COMPILE"
  fi
  if [ -d $p/lib ]; then
    export NIX_LDFLAGS="-rpath $p/lib -L $p/lib${NIX_LDFLAGS:+ }$NIX_LDFLAGS"
  fi
done
```

Now if we add dependencies (or more explicitly, dependent derivations) to `buildInputs`, the dependent derivations' `lib`, `include` and `bin` paths will all be automatically made available by `setup.sh`.

The `-rpath` flag in `ld` is needed because at runtime, the executable must use exactly that version of the library.

If unneeded paths are specified, the fixup phase will shrink the `rpath` for us.

So finishing up, we have an updated `graphviz.nix`:


```
let
  pkgs = import <nixpkgs> {};
  mkDerivation = import ./autotools.nix pkgs;
in mkDerivation {
  name = "graphviz";
  src = ./graphviz-2.38.0.tar.gz;
  buildInputs = with pkgs; [ gd fontconfig libjpeg bzip2 ];
}
```

Re-building our `graphviz` with `nix-build graphviz.nix`, its utilities are now `png` capable.

Now, running

```
$ echo 'graph test { a -- b }' | ./result/bin/dot -Tpng -o test.png
```

will output a png file.

## The repository expression

Now with `hello.nix` and `graphviz.nix`, what's a good way to organise them into a single repository?  We will do so with the `nixpkgs` convention.

We create `default.nix` in our current directory and specify:

```
{
    hello = import ./hello.nix;
    graphviz = import ./graphviz.nix;
}
```

That's it.

We can build through `default.nix` like this:

```
$ nix-build default.nix -A hello
```

Or if we want to build `graphviz`,

```
$ nix-build default.nix -A graphviz
```

The `-A` flag is how we access an attribute of the set from the given `.nix` expression (`default.nix`) in this case.

`default.nix` is also the default nix expression used when we run `nix-build`.  Meaning that we can install `hello` with just:

```
$ nix-build -A hello
```

The equivalent command using `nix-env` is:

```
$ nix-env -f . -iA graphviz
```

This is essentially the basic behaviour of `nixpkgs`.

## The inputs pattern


