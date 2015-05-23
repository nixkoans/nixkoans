# Build runtime dependencies

The `drv` path for `hello.nix` is shown by `nix-instantiate`:

```
$ nix-instantiate hello.nix
/nix/store/sfnldw9rsy40lgf5cw6rjnnpxhir4h6y-hello.drv
```

We can inspect our `.drv` file with the `nix-store` command:

```
$ nix-store -q --references `nix-instantiate hello.nix`
/nix/store/0q6pfasdma4as22kyaknk4kwx4h58480-hello-2.9.tar.gz
/nix/store/1cb8bsxi9sgavh0nbc6300zxd0mcacaq-gawk-4.1.0.drv
/nix/store/9v5m97205qy7crzgfafmyilqi5jqcphm-binutils-2.23.1.drv
/nix/store/bqym0d558wch841xglkgqy2n3pjcv0ig-gnused-4.2.2.drv
/nix/store/f31xlwjq3m5ih7g4gsla1iaf7yb3yrnd-coreutils-8.23.drv
/nix/store/nbnblp99rbm4lf12xq81ngr9wpq3gfqq-bash-4.3-p30.drv
/nix/store/byg713y23myqd244hcfripxlnyi0sm44-gcc-wrapper-4.8.3.drv
/nix/store/csrbn4bl2dij91v6p9l4vfcy2ww76lkj-gnutar-1.27.1.drv
/nix/store/i15x75737ighz8xvg8456lm2vkix9c7l-gnumake-3.82.drv
/nix/store/l1afibav295nb52kmafgcj918f7p3655-gzip-1.6.drv
/nix/store/mz0b0dfm8v2v0yl4n4xs9xba836bnaj0-builder.sh
/nix/store/pr8b6x7hdz75wmhs2r4xff0901d7zdnq-gnugrep-2.20.drv
```

Why are we looking at our `.drv` files?  Because the `hello.drv` file is the representation of the build action to perform in order to build the hello out path. Therefore, our `.drv` file will also contain the input derivations needed to be built before it can build hello. We can also refer to our input derivations as our build dependencies.

Build dependencies are recognized by Nix once they are used in any derivation call.  But we did not specify any runtime dependencies.

So how do we discover our runtime dependencies? Essentially, we have to run `nix-store -q --references` on our realised build. As we recall, we realise our build from the intermediary `.drv` file by using the `nix-store -r` command on our `.drv` file. So, composing this knowledge, we arrive at:

```
$ nix-store -q --references $(nix-store -r `nix-instantiate hello.nix`)
/nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20
/nix/store/lg4pnma41vc1vvlb4qsriphk7sq4762r-gcc-4.8.3
/nix/store/yfqx0h6mf7b5bi5bx52g8vsxn9dmbfj5-hello
```

If our `hello` program is already built, we can of course, shorten the above to:

```
$ nix-store -q --references `which hello`
/nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20
/nix/store/czwws60n5qfcif77nban2mrl9myfgrzp-hello-2.8
```

Ah, as you can see, `glibc` is a runtime dependency.  But what about `gcc`. Why does it show up in the first command and not in the second command? `gcc` shouldn't be a runtime dependency at all.

```
$ strings result/bin/hello | grep gcc
/nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20/lib:/nix/store/lg4pnma41vc1vvlb4qsriphk7sq4762r-gcc-4.8.3/lib
```

Nix added `gcc` because its out path is mentioned in the `hello` binary. This is because of the `ld rpath` - the list of directories where libraries can be found at runtime.  In other linux distros, this is usually not abused in this manner since `gcc` will be assumed to be in the shared global path like `/usr/bin` for instance.  But in Nix, we have to refer to particular versions of libraries, so `rpath` is being "abused" to serve this goal.

The Nix build process adds the `gcc` lib path thinking it may be useful at runtime but it really isn't. To get rid of it post-build, Nix authors wrote a tool called `patchelf`, which is able to reduce the `rpath` to the paths that are really used by the binary. And even after reducing the `rpath`, the `hello` binary would still depend upon gcc because of debugging information.  The well known `strip` can be used for this purpose.

This is achieved by a post build/installation phase which we refer to as the `fixup` phase.  We add this to the end of `builder.sh`:

```
$ find $out -type f -exec patchelf --shrink-rpath '{}' \; -exec strip '{}' \; 2>/dev/null
```

(And btw, since we want `builder.sh` to use `find`, `patchelf` and `strip`, we should ensure that we also update our `baseInputs` to include `findutils` and `binutils` as base build dependencies)

Now, we rebuild `hello.nix` and inspect the runtime dependencies again:

```
$ nix-build hello.nix
... building ...

$ nix-store -q --references $(nix-store -r `nix-instantiate hello.nix`)
/nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20
/nix/store/f53fpxsrgrdkw2qhv4wkva14h2b6pcgh-hello
```

We now have the expected output where `glibc` is the only expected dependency in our simple `hello` program.

This package is self-contained. If we copy its closure on to another machine, we will be able to run it.  The `hello` binary will use that exact version of `glibc` library and interpreter and not the system one.

```
$ ldd result/bin/hello
    linux-vdso.so.1 (0x00007ffcbb34a000)
    libc.so.6 => /nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20/lib/libc.so.6 (0x00007f5939a47000)
    /nix/store/la5imi1602jxhpds9675n2n2d0683lbq-glibc-2.20/lib/ld-linux-x86-64.so.2 (0x00007f5939de4000)
```
