# Garbage Collector

Most other package managers (dpkg) have a way to remove unused software.  Nix is a lot more precise compared to other systems. With other package managers, one will most likely end up with some unncessary package installed or dangling files.  With nix, this does not happen.

We decide whether a store path is still needed the same way garbage collector in programming languages decide whether an object is alive.
