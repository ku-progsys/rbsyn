# AI fixes to review later

*AI generated log, 2026-10-09.* Fixes made while debugging `test/benchmark/diaspora/user_confirm_email_benchmark.rb`.
Each one is in the code with the old lines commented out (`# AI altered`) and the new ones marked (`# AI generated`).
Status for all: **made and tested on this benchmark only; not yet reviewed by you.**

| # | Fix | File | One-line reason |
|---|-----|------|-----------------|
| 1 | `newsuccess`/`newerror` flags now reset | `lib/rbsyn/ast/infer_types.rb` | Reset used different variable names, so the flag stayed true and the whole work list was re-scored every iteration (very slow). |
| 2 | Re-score on new errors too | `lib/rbsyn/syn_helper.rb` | Only new successes triggered re-scoring; new errors were ignored. |
| 3 | Learned class methods registered as class methods | `lib/rbsyn/ast/infer_types.rb` | `DiasporaUser.exists?` was being registered as an instance method, producing `arg0.exists?(...)` candidates that always fail. |
| 4 | Finished programs de-duplicated by source code | `lib/rbsyn/syn_helper.rb` | The same program was searched once per inferred signature (e.g. `arg0.email = nil` four times). |
| 5 | Faster sorting (`prog_size` cached, redundant sort removed, `sort_by`) | `lib/rbsyn/prog_wrapper.rb`, `lib/rbsyn/syn_helper.rb` | Sorting the work list took most of the run time. |
| 6 | Comparator sign fix | `lib/rbsyn/syn_helper.rb` | A program that passed more assertions never ranked higher. |
| 7 | `binding.pry` in the old `INSTRUMENTATION R` block commented out | `lib/rbsyn/syn_helper.rb` | Stopped unattended runs (and would drop you into pry with `DBG_DYN=1`). |
| 8 | Variance filter exempts `%dyn` | `lib/rbsyn/prog_wrapper.rb` | RDL treats `%dyn` as a subtype of everything, so the filter rejected every `%dyn` candidate once library types were blocked. |
| 9 | `TrackerRewrite` keeps processed children | `lib/rbsyn/ast/track_rewrite.rb` | Nested moi calls were not instrumented, and later calls read the wrong argument-type slot, so wrong types were recorded. |
| 10 | `RefineTypesPass` tolerates a missing signature | `lib/rbsyn/ast/refine_types_pass.rb` (now `RefineTypesV2`) | Crashed on `nil != arg1` because `!=` had never been learned for a `nil` receiver. |
| 11 | Precedence fix in `generate` | `lib/rbsyn/syn_helper.rb` | `test_outputs.all? true && !add_dyn` was read as `all?(false)` during inference, accepting programs whose outputs were all `false`. |
| 12 | Class receivers also search `[s]DynamicType` during inference | `lib/rbsyn/type_ops.rb` (`methods_of`) | Class-method placeholders (`'self.exists?'`) are stored under `[s]DynamicType`, which was never searched, so `DiasporaUser.exists?` was never offered once library types were blocked. This was the last blocker: the benchmark passes (60.5s, run dev56). |
| 13 | `ExtractASTPass` copies the environment shallowly | `lib/rbsyn/ast/extract_ast_pass.rb` | The full `Marshal` deep copy per combination copied every expanded alternative (12 MB for hash-key variants, up to 81s per expansion). Checked identical to the deep copy on 7,200+ combinations; `EXTRACT_DEEP_COPY=1` restores it. |

## Design changes made with your agreement (for reference)

- Blocking all pre-existing types in `ParentsHelper.subtract()` (`lib/rbsyn/type_helper.rb`)
- Carrying declared `DynamicType` read/write effects onto learned signatures (`lib/rbsyn/ast/infer_types.rb`)
- Spec: getter declarations for `email` / `confirm_email_token`, added to `moi`
- `RefineTypesV2` merging the two refinement passes (`lib/rbsyn/ast/refine_types_v2.rb`)
- Cheaper copies in `methods_of` / `merge_methods` (`lib/rbsyn/type_ops.rb`)
- `SWEEP_DYN=1` single-pass inference (`lib/rbsyn/syn_helper.rb`)
- `InstrumentedAssertions` (`lib/rbsyn/instrumented_assertions.rb`)
- Separate search orders for inference on/off (`lib/rbsyn/syn_helper.rb`)
- `%dyn` argument exhaustion (`lib/rbsyn/dyn_arg_exhaustion.rb`)
- Work-list deduplication key `structure_hash` + learned-type write-back into hole-free candidates (`lib/rbsyn/prog_wrapper.rb`, `lib/rbsyn/learned_type_writeback.rb`); the sibling check keeps `typehash`
- Spec type guard: later specs run typed-only unless their argument/assertion types are new (`lib/rbsyn/spec_type_guard.rb`, `lib/rbsyn/synthesizer.rb`)
- Merge-step condition searches: typed first, inference pass after 190 iterations without a solution (`SynHelper#generate_typed_then_inference`, `lib/rbsyn/prog_tuple.rb`)

## Known limitation logged

- For class receivers, rbsyn follows only the superclass chain (`[s]Klass` keys), not modules mixed in as class methods via `extend` (Ruby's `singleton_class.ancestors` includes them). Irrelevant while outside types are blocked.

## Also logged elsewhere

- `docs/instrumentation_known_issues.md`: where instrumented calls can behave differently from normal ones.
- Setters chosen as branch conditions (e.g. `arg0.unconfirmed_email = true`): ignore unless it becomes the main cause of a failure.
