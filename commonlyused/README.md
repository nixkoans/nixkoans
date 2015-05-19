# Commonly Used Commands

## nix-env --list-generations

```
[calvin@nixos:~]$ nix-env --list-generations
   1   2015-05-18 19:56:11
   2   2015-05-18 19:58:07
   3   2015-05-18 20:01:01
   4   2015-05-18 20:02:34
   5   2015-05-19 01:43:34
   6   2015-05-19 02:57:56
   7   2015-05-19 02:59:34
   8   2015-05-19 03:26:50
   9   2015-05-19 03:27:50   (current)
```

Root user has its own set of generations

```
root$ nix-env --list-generations
   1   2015-05-19 03:47:45
   2   2015-05-19 03:48:22
   3   2015-05-19 03:48:48
   4   2015-05-19 03:54:11
   5   2015-05-19 04:26:52   (current)
```

## NixOS channels

### Which channel are we on?

```
root$ nix-channel --list
nixos https://nixos.org/channels/nixos-14.12
```

### Use a specific channel

There are 3 options:

* stable channel: e.g. `nixos-14.12`
* unstable channel, i.e. `nixos-unstable`
* small channel, e.g. `nixos-14.12-small` or `nixos-unstable-small`

```
nixos 0 Tue May 19 11:33:00 |~|
root$ nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nixos 0 Tue May 19 11:39:07 |~|
root$ nix-channel --list
nixos https://nixos.org/channels/nixos-unstable
```

We can then upgrade NixOS to the latest version in our chosen channel by running:

```
root$ nixos-rebuild switch --upgrade
```

### Update channel

```
root$ nixos-channel --update nixos
```
