# Inputs Design Pattern

We have packaged an hello world program so far. What if we want to create a repository of multiple packages?

## Repositories in Nix

Nix is a tool for build and deployment (installation).  Nix does not enforce any particular repository format. A repository of packages is the main usage for Nix but is not the only possibility.  A repository of packages is a consequence of us organizing packages.

Nix is a language and we can choose the format of our own repository and so there is no preset directory structure or preset packaging policy.

The `nixpkgs` repository has a certain structure which is the result of evolution and community conventions over time.  Because there are some packaging tasks which are repeated again and again except for different software, these become identified patterns and gets reused when the community thinks that it is a good way to package the software.

## The single repository pattern

Before introducing the "inputs" pattern, let's talk about the "single repository" pattern.

Systems like Debian scatter packages in several small repositories.  From a package maintainer perspective, this actually makes it hard to track interdependent changes and to contribute to new packages.

Systems like Gentoo, on the other hand, put package descriptions all in one single repository.

Nix adopts a pattern much like Gentoo's.  The nix reference for packages is `nixpkgs`, a single repository of all descriptions of all packages.

The natural implementation in Nix is to create a top-level Nix expression, and one expression for each package.  The top-level expression imports and combines all expressions in a giant attribute set with `name -> package` pairs.  Fortunately, because Nix is a lazy language (like Haskell), it evaluates only what's needed so memory requirements are minimal for this giant attribute set.

## Packaging graphviz

Grab the graphviz source from <a href="http://www.graphviz.org/pub/graphviz/stable/SOURCES/graphviz-2.38.0.tar.gz">http://www.graphviz.org/pub/graphviz/stable/SOURCES/graphviz-2.38.0.tar.gz</a>.

Referencing:

* graphviz.nix; and
* autotools.nix (which is re-used from our generic builder for hello.nix)
* builder.sh


