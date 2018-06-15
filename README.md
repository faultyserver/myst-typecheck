# Myst Typecheck

This repository is an experiment at implementing static type checking and inference for Myst. This is implemented _outside_ of the Myst project itself for two reasons:

- To show how Myst can be embedded in other Crystal programs.
- To allow more featureful development without needing to constantly rebase changes from the Myst project.

In fact, this could continue to live as its own project for eternity, though it would be markably less useful in that case. The end goal is to create a checking and inference system stable enough to be merged into the langauge itself.


# Implementation

The typechecker will be implemented as multiple visitors (phases) that progressively type the entirety of a given program. Multiple passes are needed to properly support typing for things like instance variables, whose types are given as the union of all assignments made to them, and reverse-ordered definitions, where methods defined _after_ a given method can be invoked from that method without requiring a previous declaration.

In order, these phases include:

- **Program expansion:** Find all `Require` node in the program, evaluating it, and adding the program parsed from it as a child of that node. Note that this only works for `require` expressions that use string literals for their path. This way the entire program can be expanded statically without evaluating any code.

- **Definitions:** Find all definition nodes (`Def`, `TypeDef`, `ModuleDef`) and create the type environment for the program. After this phase, all types that exist in the program should be known. This phase also handles `include` and `extend` expressions.

- **IVar construction:** Infer the types of all instance variables for every type in the program. As mentioned above, this must be done as a whole, since instance variables are mutable and can have their type changed by multiple, distinct pieces of code. This phase determines the type union for each instance variable from all assignments to it.

- **Main typing:** Now that the environment is fully set up, we can visit all of the main code in the program and infer types for every node in it. After this phase, (almost) every node in the AST should have a type set for it.
