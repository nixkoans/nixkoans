# Derivation

## The fundamentals of a derivation

Derivations are the building blocks of a Nix system, from a file system perspective.

Of all the `builtins` (built-in functions), `derivation` is the most important and form the basis of Nix builds.  The `derivation` function takes a set argument with must contain at least:

* `system` - value must be a string specifying a Nix platform identifier, e.g. 'i686-linux' or 'powerpc-darwin'
* `name` - as an identifier name which is used for the package by nix-env. Can be seen in the nix store as `hash`-`name`.
* `builder` - identifies the program which is executed to perform the build (which can be a nix file or a `.sh` file)

Our system as seen by Nix:

```
nix-repl> builtins.currentSystem
"x86_64-darwin"
```

We will get "x86_64-linux" as the output from the function if we are on a linux 64-bit machine, naturally.

We can use our `derivation` function like this:

```
nix-repl> d = derivation { name="myname"; builder="mybuilder"; system="mysystem"; }

nix-repl> d
«derivation /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv»
```

A `.drv` file is created but not built. It's the equivalent of `.o` files. An intermediate file that describes how to buuild a derivation with bare minimum information.
We can think of our `.nix` files as the equivalent of `.c` files.
And `out paths` are the actual product of our builds.

If we open up our `.drv` file, we will see this:

```
Derive([("out","/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname","","")],[],[],"mysystem","mybuilder",[],[("builder","mybuilder"),("name","myname"),("out","/nix/store/40s0qmrfb45vlh6610rk29ym318    dswdr-myname"),("system","mysystem")])
```

We can also use the `pp-term` program to print out our `.drv` files.  We get the `pp-term` program through via:

```
niv-env -i strategoxt
```

Now, we can use `pp-aterm` to pretty pretty our `.drv` files:

```
$ pp-aterm -i /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv$ pp-aterm -i /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv
Derive(
  [("out", "/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname", "", "")]
, []
, []
, "mysystem"
, "mybuilder"
, []
, [ ("builder", "mybuilder")
  , ("name", "myname")
  , ("out", "/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname")
  , ("system", "mysystem")
  ]
)
```

The `out` path for our build is already created in our `.drv` although it does not exist on our filesystem as yet.

The `.drv` format will contain the `out`put paths (multiple paths can exist).  By default, nix creates one `out` path called `out`.  The list of input derivations will also be included if there are needed.  None exist in this example because we did not provide any.  Otherwise, there would be a list of other `.drv` files.

The system and build executable will also be included (even if we pass in fake values).

A list of environment variables are also passed to the builder and would be seen in the `.drv` file. Note that our builder will *not* inherit any variable from our running shell. `nix` and `.drv`s are deterministic.  Introducing environment variables from our shell will create non-deterministic behavior which is *bad*.

Now, we can trigger a build.

```
nix-repl> :b d
these derivations will be built:
  /nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname.drv
building path(s) ‘/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname.drv’
error: a ‘mysystem’ is required to build ‘/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname.drv’, but I am a ‘x86_64-darwin’
```

We can also trigger the build from our `.drv` file outside of `nix-repl`.

```
$ nix-store -r "/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv"
these derivations will be built:
  /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv
building path(s) ‘/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname’
error: a ‘mysystem’ is required to build ‘/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv’, but I am a ‘x86_64-linux’
```

And we will get the same output and errors, of course. Because we are giving fake values to our derivation function.

## Other Useful Built-in Functions

As we can see, the returned value from our `derivation` is simply a set.  Our built-in function `isAttrs` validates this observation.

```
nix-repl> builtins.isAttrs d
true
```

We can also validate this with `typeOf`:

```
nix-repl> builtins.typeOf d
"set"
```

What are the keys in our `d` set?

```
nix-repl> builtins.attrNames d
[ "all" "builder" "drvAttrs" "drvPath" "name" "out" "outPath" "outputName" "system" "type" ]
```

And what are the values?

```
nix-repl> builtins.attrValues d
[ [ ... ] "mybuilder" { ... } "/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv" "myname" «derivation /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv» "/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname" "out" "mysystem" "derivation" ]
```

To recall the input we gave to `d`?

```
nix-repl> d.drvAttrs
{ builder = "mybuilder"; name = "myname"; system = "mysystem"; }
```

To get the path to our `.drv` file, we can run:

```
nix-repl> d.drvPath
"/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv"
```

One of the interesting attributes in our derivation is `type`.

Recall:

```
nix-repl> builtins.attrNames d
[ "all" "builder" "drvAttrs" "drvPath" "name" "out" "outPath" "outputName" "system" "type" ]
```

What's the type of type?

```
nix-repl> d.type
"derivation"
```

The type attribute isjust a convention for Nix and for us to understand that the set that we give to our `derivation` functioon is a derivation.

Finally, what we are really interested in are the outputs.  Our derivation will give us

```
nix-repl> d.outPath
"/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname"

nix-repl> d.drvPath
"/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv"

nix-repl> d.out
«derivation /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv»
```

The `outPath` is the build path in the nix store (`/nix/store`).

## Referring to other derivations

We can also get the `outPath` by using the `toString` function.

```
nix-repl> builtins.toString d
"/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname"
```

`toString` explicitly looks up for an `outPath` key. SO if we attempt to use the `toString` function on sets that do not have an `outPath` key, we get an error.

```
nix-repl> builtins.toString { outPath = "foo"; }
"foo"

nix-repl> builtins.toString { a = "foo"; }
error: cannot coerce a set to a string, at "(string)":1:1
```

`toString` will be used as a convenient way to help us refer to other derivations which may be dependencies in our derivation.

For instance, if we want to use binaries from a package `coreutils`:

```
nix-repl> :l <nixpkgs>
Added 4874 variables.

nix-repl> coreutils
«derivation /nix/store/n3vxcfq1dcw7jkrm3r5nninsf5d4qcjq-coreutils-8.23.drv»

nix-repl> builtins.toString coreutils
"/nix/store/y8z8y3snkh1p2fr7hg089jzids15d835-coreutils-8.23"
```

Note that inside nix strings (i.e. ""),  we can interpolate nix expressions with the `${...}` symbol. For instance,

```
nix-repl> "${d}"
"/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname"
```

Therefore, we can do the same for coreutils,

```
nix-repl> "${coreutils}"
"/nix/store/y8z8y3snkh1p2fr7hg089jzids15d835-coreutils-8.23"
```

This means that we can easily refer to our dependencies' binaries like this:

```
nix-repl> "${coreutils}/bin/true"
"/nix/store/y8z8y3snkh1p2fr7hg089jzids15d835-coreutils-8.23/bin/true"
```

Let's test it out!

```
nix-repl> :l <nixpkgs>
Added 4542 variables.

nix-repl> d = derivation { name = "myname"; builder = "${coreutils}/bin/true"; system = builtins.currentSystem; }

nix-repl> :b d
these derivations will be built:
  /nix/store/7ksna1lysiizxkdis3vk9pnji95jqlh7-myname.drv
building path(s) ‘/nix/store/0rz8yxaq7xzhn7gyglff508hpkwxh6pd-myname’
builder for ‘/nix/store/7ksna1lysiizxkdis3vk9pnji95jqlh7-myname.drv’ failed to produce output path ‘/nix/store/0rz8yxaq7xzhn7gyglff508hpkwxh6pd-myname’
error: build of ‘/nix/store/7ksna1lysiizxkdis3vk9pnji95jqlh7-myname.drv’ failed
```

The build is expected to fail of course since `coreutils` isn't really a builder.  We are simply trying to let `nix` become aware of `coreutils` and as you can see below, `coreutils` get added as a dependency in our derivation.

```
$ pp-aterm -i /nix/store/7ksna1lysiizxkdis3vk9pnji95jqlh7-myname.drv
Derive(
  [("out", "/nix/store/0rz8yxaq7xzhn7gyglff508hpkwxh6pd-myname", "", "")]
, [("/nix/store/f31xlwjq3m5ih7g4gsla1iaf7yb3yrnd-coreutils-8.23.drv", ["out"])]
, []
, "x86_64-linux"
, "/nix/store/wc472nw0kyw0iwgl6352ii5czxd97js2-coreutils-8.23/bin/true"
, []
, [ ("builder", "/nix/store/wc472nw0kyw0iwgl6352ii5czxd97js2-coreutils-8.23/bin/true")
  , ("name", "myname")
  , ("out", "/nix/store/0rz8yxaq7xzhn7gyglff508hpkwxh6pd-myname")
  , ("system", "x86_64-linux")
  ]
)
```

Now, we see that `coreutils` has been added as a dependency in our derivation. and coreutils' `.drv` intermediary file gets created before the rest of the build continues.

Note that the derivation is not built during evaluation of Nix expressiojns.  That is why we have to run `:b drv` in `nix-repl` or use `nix-store -r`.

There are two distinct phases when building a nix package.

* Instantiate/evaluation: nix expression is parsed, interpreted and finally returns a derivation set.  During evaluation, we can refer to other derivations because Nix will create `.drv` files and we all know out paths beforehand.  This is achieved under-the-hood with `nix-instantiate`.

* Realise/build: the `.drv` from the derivation set is built, first building `.drv` inputs (build dependencies).  This is achieved by the `nix-store -r` command.

They are analogous to the compile time and link time in C/C++ projects, i.e. compilation of source files into object files.  And subsequent linking of object files into a single executable.

In Nix, the Nix expressions (.nix) is compiled to `.drv` and then each `.drv` is built and finally, the product is installed in the relative out paths.

This is the fundamentals of all Nix derivations.  With the derivation function, we provide a set of information on how to build a package, and we get back the information about where the package was built.

## A working derivation

Begin writing our `builder.sh`:

```
declare -xp
echo foo > $out
```

Let's test our `builder.sh` build script.

```
nix-repl> :l <nixpkgs>
Added 4874 variables.

nix-repl> d = derivation { name = "foo"; builder = "${bash}/bin/bash"; args = [ ./builder.sh ]; system = builtins.currentSystem; }

nix-repl> :b d
these derivations will be built:
  /nix/store/1j7ir2h4vvqld383d1hh2vvwa15ylxrf-foo.drv
these paths will be fetched (1.12 MiB download, 6.54 MiB unpacked):
  /nix/store/rx5rbls0h72cdp3a1jfnzpnfvffrri6g-bash-4.3-p33
fetching path ‘/nix/store/rx5rbls0h72cdp3a1jfnzpnfvffrri6g-bash-4.3-p33’...

*** Downloading ‘https://cache.nixos.org/nar/14naifl0dfaba25gyqxhf3aq7fny1bz4c867kj0bn8id02aw2fdn.nar.xz’ to ‘/nix/store/rx5rbls0h72cdp3a1jfnzpnfvffrri6g-bash-4.3-p33’...
################################################################### 100.0%

building path(s) ‘/nix/store/3l36splsfx98s0bszckgh5r2170pkb55-foo’
declare -x HOME="/homeless-shelter"
declare -x NIX_BUILD_CORES="8"
declare -x NIX_BUILD_TOP="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x NIX_STORE="/nix/store"
declare -x OLDPWD
declare -x PATH="/path-not-set"
declare -x PWD="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x SHLVL="1"
declare -x TEMP="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x TEMPDIR="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x TMP="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x TMPDIR="/private/var/folders/kl/_52jng9s6sl2knv_0jds9w140000gn/T/nix-build-foo.drv-0"
declare -x builder="/nix/store/rx5rbls0h72cdp3a1jfnzpnfvffrri6g-bash-4.3-p33/bin/bash"
declare -x name="foo"
declare -x out="/nix/store/3l36splsfx98s0bszckgh5r2170pkb55-foo"
declare -x system="x86_64-darwin"
warning: you did not specify ‘--add-root’; the result might be removed by the garbage collector
/nix/store/3l36splsfx98s0bszckgh5r2170pkb55-foo

this derivation produced the following outputs:
  out -> /nix/store/3l36splsfx98s0bszckgh5r2170pkb55-foo
```

And we have now successfully built our first package "foo", albeit a pretty useless package. :-D

The output shows us the builder environment because we do so in our `builder.sh`.  `declare -xp` shows us all the environment variables that are present in the builder's environment.

* As you can see, the `$HOME` we are familiar is not `~`, or in my case on my Mac, it is not `/Users/calvin`; or if I were running `:b d` to execute the build script `./build.sh` in my NixOS instance as root, it is not `root`.
* `$PATH` is also not set so even on my Mac OS X, the builder has no awareness of all the `$PATH` I have set on my Mac OS X.
* `NIX_BUILD_CORES` and `NIX_STORE` are nix-specific variables.
* `PWD` and `TMP` shows the nix created temporary build directory.
* Subsequent to this, `builder`, `name`, `out` and `system` are variables set due to the `.drv` contents.

Compared to `autotools`, this will be the `--prefix` path.  There's no `DESTDIR` because `$out` (like `--prefix`) allows us to build in a stateless manner.  Packages are not installed in a global common path under `/`.  Packages are installed in a local, isolated path under the `nix store` slot.
