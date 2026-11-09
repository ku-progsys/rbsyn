# Todos (2026-11-05)

Next session, first: pass `wrap: false` in `InferTypes#register_learned`, so a learned signature cannot wrap the real
method. Do this before item 4.

1. Clean up `lib/rbsyn/ast/infer_types.rb` to make the error system modular: error handlers loaded from a separate
   `error_handlers` file.
2. Collapse `RefineTypesV2` and `CheckErrorPassV2` into one pass.
3. Update concretized programs only after execution, and only if a new type was discovered.
4. Cleanly separate collection from computation in `InferTypes`: `w_instrument` only collects what each call did, and
   merging and registering types is computed later, from what was collected.
5. Test the spec type guard (`lib/rbsyn/spec_type_guard.rb`). It skips inference for a later spec when its argument
   types and assertion calls were seen before, but the branch condition depends on the setup, not the assertions, and
   can need methods no earlier spec used. Its fallback to inference only fires on "No candidates", not on timeout.
   Compare against `INFERENCE_EVERY_PASS=1`.
6. If time: report learned types that are too broad for the user to annotate by hand (an argument position that
   succeeded with several unrelated classes and never failed, e.g. `state_id=` in `issue_close`). Evaluate by
   simulating from run logs: what if the user had been shown the report at round N?
