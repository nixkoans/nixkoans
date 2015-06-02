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

Defining the function in a re-usable way:

```
> square = x: x * x

> square
<<lambda>>

> square 10
100
```

Defining a function that accepts more than 1 arguments:

```
> multiply = a: b: a * b

> multiply 10
<<lambda>>

> multiply 10 2
20
```

## Functions with argument sets

We can also define our `multiply` function like these:

```
> multiply = s: s.a * s.b

> multiply { a = 3; b = 4; }
12

> multiply = { a, b }: a * b

> multiple {a = 3; b = 4; }
12
```

## Default attributes

```
> multiply = { a, b ? 2 }: a * b

> multiply { a = 3; }
6
```

## Variadic attributes

i.e. passing in more attributes than the expected ones:

```
> multiply = { a, b, ... }: a * b

> multiply { a = 3; b = 4; c = 2; }
```

The above works but it also means that we cannot access `c` in our function body.

We can access `c` if we give a name to our argumet set.  Like this:

```
> multiply = s @ { a, b, ... }: a * b * s.c
```

This gives us the possibility to write a function like this:

```
nix-repl> multiply = s @ { a, b, ... }: if builtins.hasAttr "c" s then a * b * s.c else a * b

nix-repl> multiply { a = 1; b = 2; c = 3; }
6

nix-repl> multiply { a = 1; b = 2; }
2
```

We can also use `s ? a` in place of `builtins.hasAttr "c" s`.
