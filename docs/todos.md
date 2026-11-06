# Todos (2026-11-05)

1. Clean up `lib/rbsyn/ast/infer_types.rb` to make the error system modular: error handlers loaded from a separate
   `error_handlers` file.
2. Collapse `RefineTypesV2` and `CheckErrorPassV2` into one pass.
3. Update concretized programs only after execution, and only if a new type was discovered.
