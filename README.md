# Myst Typecheck

This repository is an experiment at implementation static type checking and inference for Myst. This is implemented _outside_ of the Myst project itself for two reasons:

- To show how Myst can be embedded in other Crystal programs.
- To allow more featureful development without needing to constantly rebase changes from the Myst project.

In fact, this could continue to live as its own project for eternity, though it would be markably less useful in that case. The end goal is to create a checking and inference system stable enough to be merged into the langauge itself.


# Implementation

The typechecker works in multiple phases:

- Type discovery
  - visit the AST and find all instances of `deftype` and `defmodule`, creating a type environment for the entire program.
- Method discovery
  - re-visit the AST to find the type signatures of every method in the program.
- Typecheck
  - One more pass over the AST to visit all methods call and ensure types are satisfied throughout the body of the method with the _argument_ types.


# Open questions

### Can type discovery and method discovery be put into the same phase?

Potentially. If, following Hindley-Milner-style inference, methods are given polytype signatures, then the actual concrete types can be discarded until the actual typecheck phase.

### Can method return types be restricted to types of single clauses?

As mentioned above, the ability to determine which clause will be executed is impossible without actually running the code (e.g., Myst uses dynamic dispatch, and can't be made fully static). While some cases such as parameter arity and general type restriction may work, restriction to a single clause is not always possible.

An exact specification on the algorithm for restriction like this would be needed before implementing it, as I think the result could be more confusing than helpful. Asserting that a function will return a type union of the return type of all the clauses is simple and easy to communicate. Additionally, most clauses of a given function will be returning the same type anyway, with most special cases being for `Nil`.
