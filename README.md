[![Build Status](https://github.com/awendland/webassembly-spec-abstypes/workflows/Continuous%20Integration/badge.svg)](https://github.com/awendland/webassembly-spec-abstypes/actions)

# Abstract Types for WebAssembly

This repository implements a simple of form of abstract types (very similar to [OCaml's Abstract Types](https://ocaml.org/learn/tutorials/modules.html#Abstract-types)) in WebAssembly.

By including abstract types in Core WebAssembly, there will be a mechanism to enforce higher-level abstractions such as:

* Unforgeable file handles (e.g. in [WASI](https://github.com/WebAssembly/WASI/blob/master/phases/snapshot/witx/typenames.witx#L277))
* Object types (i.e. allowing functions to only operate on a given Object)
* Object references (i.e. unforgeable addresses, e.g. referring to `a` in `let a = new Date(); a.getYear()`)

This project was created during [@awendland](https://github.com/awendland)'s undergraduate thesis which focuses on using [WebAssembly as a Multi-Language Platform](https://github.com/awendland/2020-thesis). A PDF copy of the thesis can be found at [awendland/2020-thesis/paper/thesis-harvard-2020.pdf](https://github.com/awendland/2020-thesis/blob/master/paper/thesis-harvard-2020.pdf).

The repository is based on the [reference types proposal](https://github.com/WebAssembly/reference-types) and includes all respective changes. The `proposal-reference-types-master` branch tracks upstream for easy diffing.

## Syntax Overview

The following syntax is verbose in order to ensure clarity in the operations being performed. It's likely that a more ergonomic syntax would be adopted, such as merging the `abstype_new` and `abstype_sealed` namespaces and referring to them with a single operator, as well as overloading the existing `type` instruction to support abstract types. For now, the syntax is as follows:

|                      |                                       |                    |
|----------------------|---------------------------------------|--------------------|
| `abstype_new`        | `abstype_new [IDENTIFIER] value_type` | Create a new abstract type around a given value_type (which can be another abstract type via `abstype_sealed_ref`) |
| `abstype_sealed`     | `abstype_sealed [IDENTIFIER]`         | Import a foreign abstract type. Always used within an `import` instruction, i.e. `(import "mod" "id" (abstype_sealed [IDENTIFIER]))` |
| `abstype_new_ref`    | `abstype_new_ref IDENTIFIER`          | Reference a local abstract type (i.e. one locally declared using `abstype_new`) |
| `abstype_sealed_ref` | `abstype_sealed_ref IDENTIFIER`       | Reference an imported foreign abstract type (i.e. one imported via `abstype_sealed`) |

Abstract types manifest in two ways:

* _Local_ - Local abstract types are at play when `abstype_new*` instructions are used within a given module. These abstract types are "unwrapped" within the module, and are treated as their underlying value_types. In this way, local abstract types are more like type aliases. This allows abstract types to be constructed, and only take on their abstract nature when used in a separate module.
* _Foreign / Sealed_ - Foreign, or sealed, abstract types are present when `abstype_sealed*` instructions are being used. These abstract types are treated as opaque identifiers referencing the source module instance and the export statement. These abstract types are only treated as their underlying values upon program execution (i.e. after validation). Additionally, they do not have default values, so trying to immediately use a `local` with a sealed abstract type will fail, instead, the `local` must be populated with a value provided by the sealed abstract type's source module.

All uses of `value_type` (should) have been expanded to support abstract types.

## Samples

See [test/core/abstract-types.wast](test/core/abstract-types.wast).

For something more interesting, I've configured my [awendland/2020-thesis](https://github.com/awendland/2020-thesis) repository to be runnable via [Binder](https://mybinder.org) so that you can jump right into a web-based Jupyter notebook with this `webassembly-spec-abstypes` interpreter already available and the code in `samples/` all runnable. Try it out with: [![launch Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/awendland/2020-thesis/HEAD?filepath=samples/samples.ipynb)

## Further Details

See [PR#4](https://github.com/awendland/webassembly-spec-abstypes/pull/4) which isolates all abstract type specific changes made on top of the upstream branch. The description for this PR includes additional implementation details and other resources.
