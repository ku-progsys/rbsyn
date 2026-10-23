# Paper tracking (AI generated, started 2026-10-19)

Two lists, kept up to date as changes are made. Details of each change: `docs/ai_fixes_to_review.md` and the
`# AI generated` comments in the code.

## A. Changes that would also change vanilla (re-run vanilla with them at the end)

Speedups or fixes in code that vanilla shares (typed search, AST passes, method lookup). Not applied to `~/rbsyn` yet.

| Change | Where | Effect on vanilla |
|---|---|---|
| `prog_size` cached, redundant per-iteration sort removed, `sort_by` (fixes #5) | `prog_wrapper.rb`, `syn_helper.rb` | speed |
| Cheaper copies in `methods_of` / `merge_methods` (`copy_class_methods`) | `type_ops.rb` | speed |
| `ExtractASTPass` shallow environment copy (fix #13) | `ast/extract_ast_pass.rb` | speed |
| `methods_of` result cache, invalidated on any RDL table change (2026-10-19; `NO_METHODS_CACHE=1` off) | `type_ops.rb`, `type_helper.rb`, `syn_helper.rb`, `ast/infer_types.rb` | speed |
| Finished programs de-duplicated by source (fix #4) | `syn_helper.rb` | speed, only if vanilla has overloaded signatures |
| Comparator sign fix: more passed assertions ranks higher (fix #6) | `syn_helper.rb` | **changes vanilla's search order** |

Known shared bug, not fixed: `s(..., *expanded)` splat in `ExpandHolePass#on_hole` overflows the stack at
~35k-200k alternatives (2019 code, also in vanilla).

## B. Changes that deviate from a complete search, or are not plainly part of inference (discuss implementation)

| Change | Where | Why it needs discussion |
|---|---|---|
| Hole depth cap during inference (`INFO_MAX_HOLE_DEPTH`, default 3) | `ast/expand_hole_pass.rb` | inference no longer reaches deeper holes |
| Bounded rescoring during inference (`RESCORE_TOP`, default 100; marked UNSAFE) | `syn_helper.rb` | candidates below the top 100 keep stale scores |
| `%dyn` receivers get only placeholder methods, not learned signatures from all classes (`DYN_RECV_ALL=1` restores) | `type_ops.rb` (ROLLBACK POINT) | same programs generated, but drops type info you may want kept |
| Seen-subexpression P = 0 (`INFO_SEEN=off`) | `ast/infer_types.rb` | ignores writes inside earlier siblings of the same expression |
| Information ordering: entropy score, exponential size penalty, hole P = (a*u)/((a*u)+(c*e)), 1/occ_m, decay now off | `ast/infer_types.rb`, `syn_helper.rb` | order only (complete), but defines what the inference budget reaches |
| Weighted random pick during inference (`INFO_SAMPLE=on`; off by default) | `syn_helper.rb` | non-deterministic order (seeded) |
| Exploration/exploitation pick during inference (`EXPLORE=on`, `EXPLORE_K`; off by default, 2026-10-20): exploit = fewest holes, p(explore) = n/(n+K) | `syn_helper.rb`, `prog_wrapper.rb` | order only, but greedy fewest-holes pick before any program runs (first test: user_exists timed out) |
| `!` visible only during condition search (`NO_COND_BANG=1` off) | `syn_helper.rb`, `synthesizer.rb`, `prog_tuple.rb` | exception to the %dyn-only rule |
| Spec type guard: later specs run typed-only unless their types are new | `spec_type_guard.rb`, `synthesizer.rb` | skips inference for some specs |
| Merge-step conditions: typed first, inference after 190 iterations | `syn_helper.rb` (`generate_typed_then_inference`), `prog_tuple.rb` | two-phase search |
| Single inference pass, then exhaustive typed search ("No candidates" when typed runs out) | `syn_helper.rb` | no return to inference |
| `SWEEP_DYN=1` single-pass inference | `syn_helper.rb` | alternative search mode |
| `%dyn` argument exhaustion | `dyn_arg_exhaustion.rb` | changes which `%dyn` arguments are tried |
| Exhaustion watermark = smallest size among the candidates with the fewest inferred errors (2026-10-20; `WATERMARK=all` restores the whole-list minimum) | `syn_helper.rb` `front_min_size` | candidates moved back for inferred errors no longer hold exhaustion back, so their `%dyn` arguments can be concretized before they are tried |
| Blocking all pre-existing types (`ParentsHelper.subtract`) | `type_helper.rb` | definition of the %dyn setting |

## Inference-only bug fixes (neither list: the code does not exist in vanilla, and the search stays complete)

| Change | Where |
|---|---|
| NoMethodError on the call's own receiver recorded as a failure for any arguments (`:ALL`); the check compared the receiver's value as text to its class name and never matched (2026-10-20) | `ast/infer_types.rb` `w_instrument` |
| Dead-call pruning: drop candidates containing a call on a literal or known-type variable receiver with a recorded method-missing failure (2026-10-20; `PRUNE_DEAD_LITERAL=off`, `PRUNE_DEAD_VAR=off`, `PRUNE=off`) | `dead_call_prune.rb`, `syn_helper.rb` |
| Wildcard failure records: when the message names the class of exactly one argument, other positions become `ANY` (`ERR_ANY_POS=off`); inside a hash argument, other keys become ANY (`AnyKeysHash`, `ERR_ANY_KEY=off`) (2026-10-20) | `ast/infer_types.rb` `apply_wildcards`, `ast/check_error_pass.rb` `wildcard_supertype` |
| `matches_err`: an `:ALL` record for a different receiver fell through to the per-argument comparison (raised into `binding.pry` for 3-argument calls) (2026-10-20) | `ast/check_error_pass.rb` |
| Wrong-key records: message names no input class but contains exactly one key of the call's hash argument -> that key with any value is a no-go for this receiver/method (`ERR_KEY_NOGO=off`) (2026-10-20) | `ast/infer_types.rb` `apply_key_nogo` |
| Type-level failures marked (`:type_except`): TypeError, or message names an argument's class, or wrong key (`ERR_TYPE_LEVEL=off`); pruning rule drops calls with known receiver and arguments matching one (`PRUNE_TYPE_ERR=off`) (2026-10-20) | `ast/infer_types.rb`, `dead_call_prune.rb` |
| `CheckErrorPassV2` replaces CheckErrorPass everywhere (`CHECKER=old` rolls back): pass/fail/drop per failure record, only on known types (ANY/ALL accept %dyn), nil only matches nil on both success and failure sides; used by the `PRUNE_CHECK` pruning rule (`PRUNE_CHECK=off`) (2026-10-20) | `ast/check_error_pass_v2.rb`, `ast/infer_types.rb`, `learned_type_writeback.rb`, `dead_call_prune.rb` |
