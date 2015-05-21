# Derivation

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
$ nix-store -r /nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname.drv
```

And we will get the same output and errors, of course.
