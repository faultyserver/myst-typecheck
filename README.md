# Myst Typecheck

This repository is an experiment at implementation static type checking and inference for Myst. This is implemented _outside_ of the Myst project itself for two reasons:

- To show how Myst can be embedded in other Crystal programs.
- To allow more featureful development without needing to constantly rebase changes from the Myst project.

In fact, this could continue to live as its own project for eternity, though it would be markably less useful in that case. The end goal is to create a checking and inference system stable enough to be merged into the langauge itself.
