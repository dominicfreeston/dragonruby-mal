# DragonRuby Mal

## What is it?

It's an implementation of the [mal](https://github.com/kanaka/mal) programming langugage - a Clojure-inspired lisp interpreter and learning tool - in DragonRuby. You can run it as a typical repl, load and run scripts, or embed it into your DragonRuby game and evalutate Mal code at runtime.

Under `/lib` you'll find the completed implementation available "packaged" as a single file (it's just all the relevant files copied into one).

Under `/mal` you'll find the resulting source code of the various steps of the mal process, some tests and some tasks (build, run, test, that sort of thing) that can be triggered using a tool called [babashka](https://babashka.org/).

Under `/mygame` you'll find a simple example of how you might integrate it into a DragonRuby game.

## What is it _for_?

That's a good question!

The Mal::Repl class (probably should have called it "Interpreter" or something, but there you go) can be used to evaluate Mal code and return either a string representing the results (using REP) or the resulting ast/value (using RE).

Mal values are just Ruby objects - strings are strings, integers are integers (it could quite easily be extended to support floats), Mal Kewyords are Symbols, Mal Lists and Vectors are just Ruby Arrays and Mal Maps are just Ruby Hashes.

So you _could_ write most of your game in it,  but it's probably more work than it's worth at this point and would always end up being slower than normal DragonRuby code since it's an interpreter written in Ruby itself.

It could also be a part of a game as an in-game scripting language.

But I mostly did it as a fun learning exercise.
