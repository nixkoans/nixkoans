# Basics of Nix

Nix is a package manager. It is also a programming language.

```
$ nix-instantiate --eval --expr '"Hello world"'
"Hello world"

$ nix-instantiate --eval --expr '42'
42

$ nix-instantiate --eval --expr 'true'
true

$ nix-instantiate --eval --expr '"Hello " + "world"'
"Hello world"

$ nix-instantiate --eval --expr '(400 + 2) + (-5) + (5 * 30)'
-1860

$ nix-instantiate --eval --expr '(4 * 4 * 4) < (5 * 5 * 5)'
true

$ nix-instantiate --eval --expr '2 / 3'
0

$ nix-instantiate --eval --expr '2/3'  # space is important or it will interpet this as path!
/Users/calvin/2/3
```

## nix-repl

We can save ourselves some typing by using `nix-repl`.

So `nix-env -i nix-repl`

Now we can use `nix-repl`:

```
$ nix-repl
Welcome to Nix version 1.8. Type :? for help.

nix-repl>
```

## Types

Nix is dynamically typed but we should try to be disciplined about type usage.

```
nix-repl> "Hello" + 6
error: cannot coerce an integer to a string, at "(string)":1:1

nix-repl> abort "Just not feeling it today"
error: evaluation aborted with the following error message: ‘Just not feeling it today’

nix-repl> builtins.typeOf "foo"
"string"

nix-repl> builtins.typeOf (2 + 2)
"int"

nix-repl> builtins.typeOf ("foo" + 2)
error: cannot coerce an integer to a string, at "(string)":1:18
```

For each type `T`, there is also a convenience `isT` builtin:

```
nix-repl> builtins.isInt (2 + 2)
true

nix-repl> builtins.isBool "true"
false

nix-repl> builtins.isBool true
true
```

Nix is dynamically typed but we can describe expressions with types:

```
# 6 : int
# builtins.isInt : any -> bool
# builtins.isInt 6 : bool
# builtins.typeOf : any -> string
```

## Function application

Function application uses whitespace.  We can use parenthesis too.

```
> builtins.isInt 4
true

> builtins.isInt(4)
true
```

Here's a function application with 2 arguments.

```
> builtins.div 10 5
2
```

Our `builtins.div` function can be curried.

```
> builtins.typeOf   (builtins.div)
"lambda"
> builtins.typeOf  ((builtins.div) 10)
"lambda"
> builtins.typeOf (((builtins.div) 10) 5)
"int"
```

## Defining our own function

```
> x: x * x  # int -> int
```

Using our function:

```
> (x: x * x) 3
9
```
