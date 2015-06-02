# Garbage Collector

Most other package managers (dpkg) have a way to remove unused software.  Nix is a lot more precise compared to other systems. With other package managers, one will most likely end up with some unncessary package installed or dangling files.  With nix, this does not happen.

We decide whether a store path is still needed the same way garbage collector in programming languages decide whether an object is alive.  GC roots are our store paths.

* GC roots are stored under `/nix/var/nix/gcroots`.
* If there's a symlink to a store path, then that store path is a GC root.
* Nix allows this directory to have subdirectories and it will recursively search for symlinks to store paths.

With a list of GC roots, knowing which dead store path to delete can be achieved by comparing to all our live store paths.  All dead store paths are moved to `/nix/store/trash` as an atomic operation; afterwards, the trash is emptied.

## Run the Garbage Collector

```
$ nix-collect-garbage
```

This cleans out all dead links.

Another example:

```
$ nix-env -iA nixos.pkgs.bsdgames
...

$ readlink -f `which fortune`
/nix/store/x7v07qyf20h2h91rzhvq9b3dvpzxg5ar-bsd-games-2.17/bin/fortune

$ nix-store -q --roots $(readlink -f `which fortune`)
/nix/var/nix/profiles/default-1-link

$ nix-env --list-generations
   1   2015-05-26 04:09:01   (current)

$ nix-env -e bsd-games
uninstalling ‘bsd-games-2.17’
building path(s) ‘/nix/store/ivzdnyirgssbvvwfb3hac2mm7nhdfld2-user-environment’
created 0 symlinks in user environment


$ nix-env --list-generations
   1   2015-05-26 04:09:01
   2   2015-05-26 04:12:40   (current)```

$ nix-collect-garbage
finding garbage collector roots...
deleting garbage...
deleting ‘/nix/store/fpli8mgny3qs77z5i27q1an08639m4nl-bsd-games-2.17.drv’
deleting ‘/nix/store/byfxsa2zh6g9l5i5mwjf960nxy5rdcdd-miscfiles-1.5.drv’
deleting ‘/nix/store/l63944g20xwrw3p8kf51dz8k7lsnwfkf-miscfiles-1.5.tar.gz.drv’
deleting ‘/nix/store/v0ryfpkkrinblifawswlad2lknaxs3sg-bsd-games-2.17.tar.gz.drv’
deleting ‘/nix/store/cihfwjd7yrngr05d7s66b1ilvll5f0jm-dm-noutmpx.patch.drv’
deleting ‘/nix/store/trash’
deleting unused links...
note: currently hard linking saves -0.00 MiB
5 store paths deleted, 0.02 MiB freed

$ ls /nix/store/x7v07qyf20h2h91rzhvq9b3dvpzxg5ar-bsd-games-2.17
bin  share
```

Our old store path (in the old generation) is still present because it's a GC root. All profiles and their generations are GC roots.

We can delete a GC root this way:

```
$ rm /nix/var/nix/profiles/default-1-link

$ nix-collect-garbage
finding garbage collector roots...
deleting garbage...
deleting ‘/nix/store/6vsq8krnbg92kf066h3nbfgigi4bnj6l-user-environment’
deleting ‘/nix/store/jk37pqjf9bsf1lk7qqnm5vmkykqd2a6r-user-environment.drv’
deleting ‘/nix/store/bybxp9wxpi9bgp9lqbihicmzlv9fyw0q-env-manifest.nix’
deleting ‘/nix/store/x7v07qyf20h2h91rzhvq9b3dvpzxg5ar-bsd-games-2.17’
deleting ‘/nix/store/w60qmp5xrg4n3y4pk9jwl55p4ba7yxqx-flex-2.5.39’
deleting ‘/nix/store/73219iazfyfa6b5f2hnpjvqcjkwc6745-gnum4-1.4.17’
deleting ‘/nix/store/trash’
deleting unused links...
note: currently hard linking saves -0.00 MiB
6 store paths deleted, 7.91 MiB freed

$ ls /nix/store/x7v07qyf20h2h91rzhvq9b3dvpzxg5ar-bsd-games-2.17
ls: cannot access /nix/store/x7v07qyf20h2h91rzhvq9b3dvpzxg5ar-bsd-games-2.17: No such file or directory
```

As we can see, our garbage collector has now deleted the `bsd games` completely because we removed it's link in GC root.

We removed our GC root from `/nix/var/nix/profiles` and not from `/nix/var/nix/gcroots`. `/nix/var/nix/gcroots/profiles` is a symlink to `/nix/var/nix/profiles`. This means that any profile and its generations are GC roots.

Conclusion:
1. Anything under `/nix/var/nix/gcroots` is a GC root.
2. And anything not being garbage collected is because it's referred from one of the GC roots.

## Indirect Roots

We also notice that when we build our `hello` pakcage with nix-build, a `result` symlink is built in the current directory.  Since the `hello` program is still working, it has not been garbage collected and since there's no other derivation that depends upon the `hello` package, it must be a GC root.

`nix-build` automatically adds the `result` symlink as a GC root.  These GC roots are added under `/nix/var/nix/gcroots/auto`.

```
$ ls -l /nix/var/nix/gcroots/auto/
total 0
lrwxrwxrwx 1 root root 30 May 25 18:15 qsxa7dgxwg3wn1vzwyrpgi5vc34b1q4m -> /root/nixkoans/nixshell/result
```

This is what we refer to as an indirect GC root.

We can remove this derivation from either

* `/nix/var/nix/gcroots`  itself; or
* the `result` symlink directly

Once we have done that `nix-collect-garbage` will remove our derivation from `nix-store`.

## Clean up and remove everything

```
$ nix-channel --update
$ nix-env -u --always
$ rm /nix/var/nix/gcroots/auto/*
$ nix-collect-garbage -d
```

Note that the `-d` option is used to delete old generations of all profiles and collect garbage.  After running this command, we will not be able to rollback to any previous generation. So make sure the new generation is working well before running the command.

Garbage collection in Nix is a powerful mechanism to clean up our system.  The `nix-store` command allows us to know why a certain derivation is in the nix store.

