# Nix Search Path

```
$ nix-instantiate --eval -E '<ping>'
error: file ‘ping’ was not found in the Nix search path (add it using $NIX_PATH or -I)

$ NIX_PATH=$PATH nix-instantiate --eval -E '<ping>'
/var/setuid-wrappers/ping
```

The `NIX_PATH` environment variable is similar to the `PATH` environment variable.  Nix expressions uses `NIX_PATH` and is not of much use by the nix tools themselves.

In normal shell, when we execute the command "ping", it's being searched in the `PATH` directories. The first one found is the one being used.

In nix, the same behaviour is implemented.  The only difference is that we have to use "<ping>" instead of "ping".

We can use `NIX_PATH` to override paths referred to in Nix expressions, from the command line. The example above clarifies.

We can use the `-I` flag and provide the directory too.

```
$ nix-instantiate -I /var/setuid-wrappers --eval -E '<ping>'
/var/setuid-wrappers/ping
```

Our `NIX_PATH` also accepts a different but handy syntax: "somename=somepath". So instead of providing a directory only, we can specify exactly the value of the name.

## Path to repository

```
$ nix-instantiate --eval -E '<nixpkgs>'
/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs

$ echo $NIX_PATH
/nix/var/nix/profiles/per-user/root/channels/nixos:nixpkgs=/etc/nixos/nixpkgs:nixos-config=/etc/nixos/configuration.nix
```

The first directory takes precedence and is our `nixpkgs`.

Let's take a look at what that directory contains:

```
$ ls -la /nix/var/nix/profiles/per-user/root/channels/nixos
lrwxrwxrwx 1 root nixbld 73 Jan  1  1970 /nix/var/nix/profiles/per-user/root/channels/nixos -> /nix/store/wz2qv4yzk17kq23l423zhx7wmz3xjsnf-nixos-14.12.673.0672315/nixos

$ ls /nix/store/wz2qv4yzk17kq23l423zhx7wmz3xjsnf-nixos-14.12.673.0672315/nixos
default.nix  nixos  nixpkgs  programs.sqlite
```

So, our `nixpkgs` directory is essentially a checkout of the `nixpkgs` repository at a specific commit.

We can use this fact to change `NIX_PATH` so hat we use a different set of `nixpkgs` (different version that's checked out).

So what about our own repository containing `default.nix`, `graphviz.nix` and `hello.nix`.  Can we manage them under `NIX_PATH`?

Yes and this is how we do it (assuming our `default.nix`, `graphviz.nix` and `hello.nix` are all located in $HOME/nixkoans/mypkgs):

```
$ export NIX_PATH=mypkgs=$HOME/nixkoans/mypkgs:$NIX_PATH

$ nix-instantiate --eval '<mypkgs>'
{ graphviz = <CODE>; graphvizCore = <CODE>; hello = <CODE>; mkDerivation = <CODE>; }
```

As we can see, we get a set of packages as well as the `mkDerivation` utility and these are all part of our `mypkgs` repository.

We can use `nix-build` with reference to our `mypkgs` repository in the following manners:

```
$ nix-build $HOME/nixkoans/mypkgs -A graphviz
/nix/store/3fglxgz4pfvsb3n8g7hk7flm601hrdvi-graphviz

$ nix-build '<mypkgs>' -A graphviz
/nix/store/3fglxgz4pfvsb3n8g7hk7flm601hrdvi-graphviz
```

# nix-ev

`nix-env` is a different from `nix-instantiate` and `nix-build`.

`nix-env` specifically uses `$HOME/.nix-defexpr` to find derivations.

So if we run `nix-env -i graphviz` anywhere, it will install the `graphviz` from `nixpkgs` and not from our repository.  It will still use the `graphviz` from `nixpkgs` even if we set `NIX_PATH` to point at our repository's path. `nix-env` does not use `NIX_PATH` at all.  It uses `$HOME./.nix-defexpr`.

In order to specify an alternative to `~/.nix-defexpr`, we need to use the `-f` flag.

Like this:

```
$ nix-env -f '<mypkgs>' -i graphviz
warning: there are multiple derivations named ‘graphviz’; using the first one
installing ‘graphviz’
building path(s) ‘/nix/store/vrizkigjrmfrwljsnan9kdbwsrybnn9c-user-environment’
created 4 symlinks in user environment
```

We get the warning message because both `graphviz` and `graphvizCore` have the name `graphviz` for the derivation.

Let's see:

```
$ nix-env -f '<mypkgs>' -qaP
graphviz      graphviz
graphvizCore  graphviz
hello         hello
```

So if we explicitly want a particular `graphviz` from `mypkgs`, we should use the attribute flag `-A` to say so.

```
$ nix-env -f '<mypkgs>' -iA graphviz
replacing old ‘graphviz’
installing ‘graphviz’
```
