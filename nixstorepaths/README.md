# Nix store paths

How are store paths computed?

## Source paths

Nix allows relative paths to be used, as we already know.

```
$ echo mycontent > myfile

$ nix-repl

nix-repl> derivation { system = "x86_64-linux"; builder = ./myfile; name = "foo"; }
«derivation /nix/store/y4h73bmrc9ii5bxg6i7ck6hsf5gqv8ck-foo.drv»

nix-repl> :q

$ pp-aterm -i /nix/store/y4h
y4h1z3y8qn3mvv7qx7w9mblsay60axgf-cifs-utils-6.4.tar.bz2.drv  y4h73bmrc9ii5bxg6i7ck6hsf5gqv8ck-foo.drv                     y4hfjglyhwcpmxwnjxvrgwj11j5c8iyl-lua-5.1.5.tar.gz.drv
(git::master)nixos 2 Wed May 27 09:48:53 |~/nixkoans/nixstorepaths|
root$ pp-aterm -i /nix/store/y4h73bmrc9ii5bxg6i7ck6hsf5gqv8ck-foo.drv
Derive(
  [("out", "/nix/store/hs0yi5n5nw6micqhy8l1igkbhqdkzqa1-foo", "", "")]
, []
, ["/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"]
, "x86_64-linux"
, "/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"
, []
,  ("builder", "/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile")
  , ("name", "foo")
  , ("out", "/nix/store/hs0yi5n5nw6micqhy8l1igkbhqdkzqa1-foo")])
  , ("system", "x86_64-linux")
  ]
)
```

So how did `nix` decide to use `xv2iccirbrvklck36f1g7vldn5v58vck` as our store path?

The comments in nix source code actually explains it - <a href="http://lxr.devzen.net/source/xref/nix/src/libstore/store-api.cc#97">http://lxr.devzen.net/source/xref/nix/src/libstore/store-api.cc#97</a>.

1. Compute the hash of the file
2. Build the string description
3. Compute the final hash

### Step 1: Compute the hash of the file

```
$ nix-hash --type sha256 myfile
2bfef67de873c54551d884fdab3055d84d573e654efa79db3c0d7b98883f9ee3
```

OR

```
$ nix-store --dump myfile | sha256sum
2bfef67de873c54551d884fdab3055d84d573e654efa79db3c0d7b98883f9ee3
```

### Step 2: Build the string description

```
$ echo -n "source:sha256:2bfef67de873c54551d884fdab3055d84d573e654efa79db3c0d7b98883f9ee3:/nix/store:myfile" > myfile.str
```

### Step 3: Compute the final hash

```
$ nix-hash --type sha256 --truncate --base32 --flat myfile.str
xv2iccirbrvklck36f1g7vldn5v58vck
```

## Output paths

Output paths are generated for derivations (usually).  We use the above example because it's simple.  Even if we did not build the derivation, nix knows the out path `hs0yi5n5nw6micqhy8l1igkbhqdkzqa1`.  This is because the out path only depends on inputs.

It is computed in a similar way to source paths above, except that the `.drv` is hashed and the type of derivation is `output:out`. In case of multiple outputs, we may have different `output:<id>`.

At the time nix computes the out path, the `.drv` contains an empty string for each out path.  So what we do is getting our `.drv` and replacing the out path with an empty string.

```
$ cp -f /nix/store/y4h73bmrc9ii5bxg6i7ck6hsf5gqv8ck-foo.drv myout.drv

$ cat myout.drv
Derive([("out","/nix/store/hs0yi5n5nw6micqhy8l1igkbhqdkzqa1-foo","","")],[],["/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"],"x86_64-linux","/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile",[],[("builder","/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"),("name","foo"),("out","/nix/store/hs0yi5n5nw6micqhy8l1igkbhqdkzqa1-foo"),("system","x86_64-linux")])(git::master)nixos 2 Wed May 27 10:04:36 |~/nixkoans/nixstorepaths|

$  sed -i 's,/nix/store/hs0yi5n5nw6micqhy8l1igkbhqdkzqa1-foo,,g' myout.drv

$ cat myout.drv
Derive([("out","","","")],[],["/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"],"x86_64-linux","/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile",[],[("builder","/nix/store/xv2iccirbrvklck36f1g7vldn5v58vck-myfile"),("name","foo"),("out",""),("system","x86_64-linux")])
```

With this cleaned up `myout.drv`, we are now "simulating" the .drv state where nix is when computing the out path for our derivation.

```
$ sha256sum myout.drv
1bdc41b9649a0d59f270a92d69ce6b5af0bc82b46cb9d9441ebc6620665f40b5  myout.drv

$ echo -n "output:out:sha256:1bdc41b9649a0d59f270a92d69ce6b5af0bc82b46cb9d9441ebc6620665f40b5:/nix/store:foo" > myout.str

$ nix-hash --type sha256 --truncate --base32 --flat myout.str
hs0yi5n5nw6micqhy8l1igkbhqdkzqa1
```

So this is how nix generates the out path in the .drv file.

In the case where the `.drv` has input derivations (i.e. it references other `.drv`s), then such `.drv` paths are replaced by this same algorithm which returns a hash.

## Fixed-output path

The other most used kind of path is when we know beforehand an integrity hash of a file. This is usual for tarballs.

A derivation can take three special attributes: `outputHashMode`, `outputHash` and `outputHashAlgo` which are documented in nix manual.

The builder must create the out path and make sure its hash is the same as the one declared with `outputHash`.

Using our `myfile` example again:

```
$ sha256sum myfile
f3f3c4763037e059b4d834eaf68595bbc02ba19f6d2a500dce06d124e2cd99bb  myfile

nix-repl> derivation { name = "bar"; system = "x86_64-linux"; builder = "none"; outputHashMode = "flat"; outputHashAlgo = "sha256"; outputHash = "f3f3c4763037e059b4d834eaf68595bbc02ba19f6d2a500dce06d124e2cd99bb"; }
«derivation /nix/store/ymsf5zcqr9wlkkqdjwhqllgwa97rff5i-bar.drv»

root$ pp-aterm -i /nix/store/ymsf5zcqr9wlkkqdjwhqllgwa97rff5i-bar.drv
Derive(
  [("out", "/nix/store/a00d5f71k0vp5a6klkls0mvr1f7sx6ch-bar", "sha256", "f3f3c4763037e059b4d834eaf68595bbc02ba19f6d2a500dce06d124e2cd99bb")]
, []
, []
, "x86_64-linux"
, "none"
, []
, [ ("builder", "none")
  , ("name", "bar")
  , ("out", "/nix/store/a00d5f71k0vp5a6klkls0mvr1f7sx6ch-bar")
  , ("outputHash", "f3f3c4763037e059b4d834eaf68595bbc02ba19f6d2a500dce06d124e2cd99bb")
  , ("outputHashAlgo", "sha256")
  , ("outputHashMode", "flat")
  , ("system", "x86_64-linux")
  ]
)
```

It doesn't matter which input derivations are being used, the final out path must only depend on the declared hash.
What nix does is to create an intermediate string representation of the fixed-output content:

```
$ echo -n "fixed:out:sha256:f3f3c4763037e059b4d834eaf68595bbc02ba19f6d2a500dce06d124e2cd99bb:" > mycontent.str

$ sha256sum mycontent.str
423e6fdef56d53251c5939359c375bf21ea07aaa8d89ca5798fb374dbcfd7639  myfile.str
```

Then proceed as it was a normal derivation output path:

```
$ echo -n "output:out:sha256:423e6fdef56d53251c5939359c375bf21ea07aaa8d89ca5798fb374dbcfd7639:/nix/store:bar" > myfile.str

$ nix-hash --type sha256 --truncate --base32 --flat myfile.str
a00d5f71k0vp5a6klkls0mvr1f7sx6ch
```

Hence, the store path only depends on the declared fixed-output hash.

The basic principle is the same when handling store paths - Nix first hashes teh content, then creates a string description and the final store path is the hash of this string.

Fundamentally, nix:

* knows beforehand the out path of a derivation since it only depends on the inputs
* uses fixed-output derivations are used by `nixpkgs` repository for downloading and verifying source tarballs
