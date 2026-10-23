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

## `!` visible during condition search only (2026-10-13)
- `SynHelper#with_condition_terms` (lib/rbsyn/syn_helper.rb): registers `BasicObject#!` with RDL's core signature
  `() -> %bool` (no effects) for the duration of a block, then restores the RDL table (also on exceptions).
- Used around the branch search (synthesizer.rb, `run`) and the two merge-condition searches (prog_tuple.rb).
- Reason: branch conditions like `!!arg0` / `!User.exists?(..)` need `!` on a boolean, which the inference budget
  never reaches (nested call). Agreed exception to the %dyn-only rule for an easily known term.
- `NO_COND_BANG=1` turns it off (for ablations).

## Session 2026-10-19 (information ordering work)
- Float-only arithmetic in `InferTypes#binary_entropy`, `info_score`, `hole_p_depth`: `1 - q` (Integer - Float) raised
  `RDL::Type::TypeError` when RDL wraps `Integer#-` (crashed `invitation_code_use` at 0.2s).
- Other changes of this session (information ordering, hole P, seen subexpressions, occ_m, depth cap, `%dyn` receivers
  placeholder-only, methods_of cache, cached scoring symbols): see `docs/paper_tracking.md`.
- `ProgWrapper#methods_with_write_effect` (`lib/rbsyn/prog_wrapper.rb`): `%dyn` placeholder methods (`DynamicType`)
  are offered as effect-causing methods only during inference, matching `methods_of`. Before, the typed search's
  effect search built `InvitationCode#invited_by_id=` from the placeholder, which `methods_of` does not offer when
  inference is off, and `fn_call` crashed (open_bugs item 4). user_process_invite_acceptence now passes.
- `methods_of` for `%dyn` receivers during inference (`lib/rbsyn/type_ops.rb`, ROLLBACK POINT): placeholders from both
  `DynamicType` and `[s]DynamicType` (class methods). With `DynamicType` only, the effect search built class-method
  calls like `EmailToken.confirm` on a `%dyn` receiver that `methods_of` did not offer; the NoMethodError was caught
  higher up and those candidates were silently lost (activate, check_site_contact_username).

### 2026-10-20: overview_example out of memory (RDL hash type bounds + deep copy)

- Cause: RDL records every successful `FiniteHashType <= FiniteHashType` in the types' `ubounds`/`lbounds` (bookkeeping
  for RDL's `promote!`, never used by rbsyn). Our error checks compared the argument hash type of `update_post` with
  itself ~540k times (`check_error_pass.rb` `left_intersection_supertype` 484k, `infer_types.rb`
  `consolidate_type_errors` 59k, `match_success` 16k). `fn_call`'s `Marshal.load(Marshal.dump(nested_accum))` (commit
  59de5a1, not in vanilla) then serialized the type with its bounds: 0.34 GB, then 1.1 GB per call for chains like
  `arg2[_][_]`; the bounds also collected the Marshal copies, so it grew each call until the process was killed.
- Fix 1: `TypeOperations.leq_nc` (`lib/rbsyn/type_ops.rb`): identical objects are subtypes, otherwise
  `Type.leq(..., no_constraint: true)`. Used at those 4 call sites. RDL's recursive calls drop `no_constraint`, so nested
  types still record (~42k appends remained).
- Fix 2: `ExpandHolePass#copy_nodes_share_types` replaces the Marshal copy in `fn_call`: rebuilds nodes, arrays and
  hole parameter hashes, shares RDL types. Checked equal to the Marshal copy in isolation; issue_close still passes.
- Result (INFO_ORDER=off, TIMEOUT=300): peak memory 281 MB (was 5-10 GB, killed). Still times out: inference 115 s,
  then the typed search does not find the first spec's program in the remaining 185 s (vanilla 3.2 s).

## 2026-10-20: method-missing failures never recorded for any arguments

- `InferTypes#w_instrument` (NoMethodError and NameError branches) decided whether the missing method was called on
  the call's own receiver with `e.receiver.to_s == recvr.class.to_s`, i.e. the receiver's value as text (`"name"`
  for `:name`) against its class name (`"Symbol"`). Never equal, so `trace[:args] = :ALL` was never set: every such
  failure was wrapped in ComplexError and stored once per argument type (e.g. 4 records for Symbol#username=), the
  `:ALL` branch of `CheckErrorPass#matches_err` never fired, and the consolidate_type_errors dedupe never fired.
- Fix: `e.receiver.equal?(recvr) && e.name == meth` (Ruby sets `e.receiver` to the object the method was sent to).
- Isolated check (inference only, TIMEOUT=30, INFO_ORDER=off): unstage_user 36 of 65 failure records are now `:ALL`;
  programs tested in inference 1130 -> 695, informative 10.8% -> 22.0%. activate 46 `:ALL` of 228; tested
  1030 -> 980, informative 21.9% -> 15.1%; still "No candidates". Learned successes unchanged in both (no setter on
  a model instance learned yet). Logs: ~/rbsyn_debug_logs/fix501_*.log.

## 2026-10-20: dead-call pruning and exhaustion watermark

- `lib/rbsyn/dead_call_prune.rb` (`DeadCallPrune`), used in `SynHelper#generate`: a candidate is dropped when it
  contains a call whose receiver type is known before running (a literal, or a variable with a non-%dyn type) and
  that (method, receiver type) has a method-missing failure recorded for any arguments. Applied to newly built
  children (dead finished programs are not run) and to the whole work list when a new dead pair is recorded.
  Switches: `PRUNE_DEAD_LITERAL=off`, `PRUNE_DEAD_VAR=off`, `PRUNE=off`.
- Not done: dropping finished programs that crashed on one spec. Effect statements are inserted BEFORE the
  original expression (`ProgWrapper#to_ast`), so they can change the state the crashing call sees; not safe.
- Watermark: `front_min_size` = smallest size among candidates with the fewest inferred errors (`WATERMARK=all`
  restores the whole-list minimum).
- Isolated check (inference, INFO_ORDER=off): unstage_user dropped 471 (default ITERS) / 9321 (ITERS=76) candidates,
  tested programs 695 -> 493 at default ITERS; activate dropped 810. Picked programs still all size <= 2 in both.
  unstage_user at ITERS=76 now runs setters on an AnotherUser instance (kept as successes) and `first` on an
  AnotherUser Relation (kept) - neither happened in the 2026-10-20 ITERS=76 escalation run before these changes.
  Logs: ~/rbsyn_debug_logs/prune1_*.log, prune2_unstage_user.log.

## 2026-10-20: ANY wildcards in failure records

- `InferTypes#apply_wildcards` (called from `update_errlist`): if the error message names the class of exactly one
  argument (class name, or a class value's own name; NilClass never counts), the other argument positions become
  `:ANY` (`ERR_ANY_POS=off`). If that argument is a hash and exactly one key's value class is named (and the message
  does not name Hash), it becomes `AnyKeysHash(key, type)`: that key with that type, any other keys
  (`ERR_ANY_KEY=off`). Records marked `trace[:wild]`; `consolidate_type_errors` never merges them with others.
- `CheckErrorPass#wildcard_supertype`: `:ANY` matches anything; `AnyKeysHash` matches a hash containing the key
  with a matching value type (a %dyn argument matches, as before). Missing-method records keep `args = :ALL`.
- Found while testing: RDL types raise NoMethodError on `== :ANY`, so identity / class-first comparison is used.
- Also fixed: `matches_err` let an `:ALL` record for another receiver fall through (`Symbol#size` = 3, then
  `[recvr] + :ALL` raised into `binding.pry`); it now returns false.
- Isolated check (TIMEOUT=30, INFO_ORDER=off): unstage_user 8 of 65 failure records are key wildcards, no pry
  stops, programs tested unchanged (493). No positional wildcards: every failing method takes one argument.
  overview_example (90 s) ran without pry stops; inference had not finished. Logs: ~/rbsyn_debug_logs/any2_*.log.

## 2026-10-20: wrong-key records, type-level marker, type-level sweep

- `apply_key_nogo`: no argument class named, message contains exactly one key of a hash argument of the call as a
  whole word -> `AnyKeysHash(key, :ANY)` (the key with any value), other positions :ANY. Skipped when that key's
  value is itself a hash (nested hash gives "no such column: key.key" for a key that exists). `ERR_KEY_NOGO=off`.
- `trace[:type_level]`: TypeError, or the message names an ARGUMENT's class (receiver excluded: lookups name it for
  value reasons), or a wrong-key record. Printed `=> :type_except`. Type-level and other records are not merged.
  `ERR_TYPE_LEVEL=off`.
- `DeadCallPrune` rule `PRUNE_TYPE_ERR`: drops a candidate with a call whose receiver is known (literal / known-type
  variable) and whose every argument position is ANY in a type-level record or holds a literal, known-type variable
  or literal hash matching it. Holes / %dyn arguments never match. Records containing %dyn are never used (none
  seen: 0 of 628 records in four benchmarks).
- Bug found in testing: `AnyKeysHash#==` compared an RDL type with :ANY (raises) -> consolidate_type_errors hit
  binding.pry (activate, overview_example). Fixed with identity / class-first comparison.
- Isolated check (INFO_ORDER=off): unstage_user 23 of 63 records type-level, 78 dropped by PRUNE_TYPE_ERR, tested
  467; activate 92 of 218 type-level, key no-go records for email/token/confirmed/expired on User.exists?, 5
  dropped; pod 90 of 303 type-level; user_process_invite_acceptence still passes (1.3 s); no pry stops after fix.
  Logs: ~/rbsyn_debug_logs/tl_*.log, tl2_*.log.

## 2026-10-20: CheckErrorPassV2 (replacement checker) and the nil carve-out

- UPDATE: first built as DropCheckPass (a subclass); replaced by the standalone `lib/rbsyn/ast/check_error_pass_v2.rb`,
  now used by InferTypes#check_errors, LearnedTypeWriteback and the PRUNE_CHECK rule. `check_error_pass.rb` is unchanged
  as the reference; `CHECKER=old` switches InferTypes and LearnedTypeWriteback back to it. Quick check: unstage_user,
  activate run without pry stops; user_process_invite_acceptence passes (1.3 s). Logs: ~/rbsyn_debug_logs/v2_*.log.

- `lib/rbsyn/ast/drop_check_pass.rb`, subclass of CheckErrorPass (left untouched). Same bottom-up walk; a call to a
  method of interest takes the result type of the first matching success (call results resolve as receivers). Each
  failure record gives :pass / :fail (matched with known types, not type-level; counted) / :drop (matched with known
  types, type-level or :ALL). Known = no %dyn; ANY positions and :ALL accept anything. Hooked into DeadCallPrune as
  rule `PRUNE_CHECK` (runs only when the other rules did not already drop the candidate).
- Nil carve-out: RDL ranks nil below every type (nil <= Hash, nil <= Integer, NilClass <= Hash all true). A nil
  receiver matched any success (950 missed drops on unstage_user), and a nil argument would match any failure.
  `nil_safe_leq`: nil only matches nil; used in the overridden match_success and in the failure comparison.
- :ALL receiver compared by subtype instead of ==.
- Found with it: the earlier `PRUNE_TYPE_ERR` rule (DeadCallPrune's own matching) has no nil carve-out and drops
  calls with a nil argument such as `AnotherUser.where(nil)` (which ActiveRecord accepts): 1596 such drops on
  unstage_user in 30 s. It also drops `where(true)` although a success and a type-level failure are both recorded
  for `where(true or false)` (where(false) works, where(true) raises): the bool union hides a value difference.
- Isolated check (TIMEOUT=30, INFO_ORDER=off, PRUNE_CHECK alone): activate 1678 dropped (= all earlier rules
  combined), tested 716 -> 460; unstage_user 753 dropped, tested 487. No pry stops.
  Logs: ~/rbsyn_debug_logs/dc_*.log, dd3_unstage.log, tt_unstage.log.

## 2026-10-20: run switches file

- `lib/rbsyn/run_switches.rb`, loaded first by `lib/rbsyn.rb`: sets INFO_ORDER, CHECKER, WATERMARK, PRUNE*,
  ERR_* to their current defaults unless already set in the environment (command line still overrides).
  INFO_ORDER defaults to "off" (size ordering), which every run used. Checked: user_process_invite_acceptence passes
  with no variables set on the command line.
