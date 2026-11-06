# Todos (2026-11-05)

Next session, first: pass `wrap: false` in `InferTypes#register_learned`, so a learned signature cannot wrap the real
method. Do this before item 4.

1. Clean up `lib/rbsyn/ast/infer_types.rb` to make the error system modular: error handlers loaded from a separate
   `error_handlers` file.
2. Collapse `RefineTypesV2` and `CheckErrorPassV2` into one pass.
3. Update concretized programs only after execution, and only if a new type was discovered.
4. Cleanly separate collection from computation in `InferTypes`: `w_instrument` only collects what each call did, and
   merging and registering types is computed later, from what was collected.
