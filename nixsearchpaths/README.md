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
