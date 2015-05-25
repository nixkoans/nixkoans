# Nix shell

The nix-shell tool drops us into a shell by setting up the necessary environment variables to develop a nix package/expression. nix-shell does not build the derivation, it only serves as a preparation so we can run our build steps manually.

In our nix environment, we don't have access to libraries and programs unless we install them with nix-env.  However, installing libraries with nix-env is not a good practice. Not even at user level.  NixOS encourages isolated libraries and programs at nix package level and preferably not at user level.

```
root$ nix-shell hello.nix

[nix-shell:~/nixkoans/nixshell]$ make
make: command not found

[nix-shell:~/nixkoans/nixshell]$ echo $baseInputs
/nix/store/rygv74phd82c106qynz7l0rmg4rvrlzd-gnutar-1.27.1 /nix/store/sr65fbmyvsrzd4vbgvx1pkqm6a04hzas-gzip-1.6 /nix/store/n93nwrnhj711053pxvhaj7vgi6ivxjr3-gnumake-3.82 /nix/store/w1lj2s6v2wjmgd44fdi9i1p53qbxrqdc-gcc-wrapper-4.8.3 /nix/store/b8qhjrwf8sf9ggkjxqqav7f1m6w83bh0-binutils-2.23.1 /nix/store/wc472nw0kyw0iwgl6352ii5czxd97js2-coreutils-8.23 /nix/store/z7krwqz92wxpakvf5kahq9l42rhzrlqs-gawk-4.1.0 /nix/store/nmdv0xnimpyajw8faydi8kh6dw1s3gjm-gnused-4.2.2 /nix/store/g9qkr44yllgy5cb03vmfdksmh3pbmp1s-gnugrep-2.20 /nix/store/4cd4n5729kk10jm32c14bwsk4xmsl7m3-patchelf-0.8 /nix/store/y26kh8qksgmy700fl5a882n6lwg3ma0a-findutils-4.4.2

[nix-shell:~/nixkoans/nixshell]$
```

When we source our `builder.sh`, `builder.sh` will execute and build our derivation.  Note that we may get an error in the installation phase because the user may not have the permission to write to `/nix/store`.
