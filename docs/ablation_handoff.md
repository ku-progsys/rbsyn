# Ablation handoff prompt (2026-10-20)

Paste everything below the line into a fresh Claude Code session in ~/rbsyn2/rbsyn.

---

We are running a methods-of-interest (MOI) ablation on rbsyn (branch `dirtycode`, repo ~/rbsyn2/rbsyn; vanilla
baseline in ~/rbsyn). Benchmarks are converted to `%dyn` declarations inside a `ParentsHelper.init_list() …
ParentsHelper.subtract()` window, and types are learned by inference during the run. The ablation adds one more
scrubbed `%dyn` method per round to a passing benchmark until it no longer solves in time.

Work rules (important):
- Be conservative with tokens: batch work into few, large steps. Write code in one go, run all three pool builds in
  one command, check results once. No polling (background runs notify on completion), no repeated reruns.
- Explain in plain prose paragraphs; put code names, values and file:line links in an "As seen in:" list after.
  Precise, not verbose. Answer only what is asked.
- Edit convention for code in lib/: comment out old lines with `# AI altered`, mark new lines `# AI generated`.
  The ablation scripts live in scripts/ablation/ (new files, no lib edits needed).
- When the user says stop, stop immediately.
- Gotcha: `pkill -f` / `pgrep -f` with a pattern that appears in your own shell command kills or matches your own
  shell. Anchor patterns on `bin/ruby .*rake_test_loader.rb test/benchmark/...` and use `ps -eo pid,args | grep`.

What exists (read these first, they are short):
- scripts/ablation/dump_blocked.rb: RUBYOPT hook; after the benchmark's ParentsHelper.subtract writes
  ParentsHelper.blocked (every signature the benchmark had before its %dyn window, i.e. vanilla's) and the window's
  own declarations to JSON, then exits.
- scripts/ablation/hook.rb: RUBYOPT hook for one round; injects extra %dyn declarations (from ABLATE_ROUND JSON) just
  before subtract, appends them to the define's moi (SynthesizerProxy#initialize), and at exit writes ABLATE_OUT JSON:
  moi available, types learned, types rejected hard (args :ALL or trace[:type_level]) / soft (the rest).
- scripts/ablation/ablate.rb: runner for ONE benchmark. Builds the pool once (dump, scrub, dedupe, skip names already
  in the window, seeded shuffle, load check), then rounds: round r = first r pool methods, TIMEOUT=limit (default
  1200 s), one CSV row per round, checkpoint.json (order + next_round) so rerunning resumes; stops at the first round
  that does not PASS. Lock file so only one ablation runs at a time. Output: ~/rbsyn_debug_logs/ablation/<bench>/.
  CSV columns: benchmark, round, n_added, added_moi, result, solve_time_s, types_learned, types_rejected_hard,
  types_rejected_soft, moi_available.
- Scrub rule: same argument count, every type %dyn, `wrap: false`; effects on the method's own class -> 'self',
  other effects reduced to their class name, '*' kept; class methods ("[s]X" keys) become 'self.name'.
- Run switches (search defaults) are set in lib/rbsyn/run_switches.rb; nothing needs to be set on the command line.

What is wrong with the current pool and must be fixed first:
1. Too wide. All models of the whole suite are loaded for every benchmark, so the dump has 272 methods on 25
   classes for issue_close, including unrelated models (Mastodon, Diaspora...). Vanilla only reaches methods on
   types reachable from the benchmark. Restrict the pool to VANILLA-REACHABLE classes:
   - start set: the define's function type (argument and return types; for generics the base and params; for finite
     hashes the value types) and its components list (each class constant gives the class and its singleton "[s]X");
   - add the ancestors of each reachable class that appear in the dump (e.g. ActiveRecord::Base, BasicObject; for a
     reachable singleton "[s]Model" also "[s]ActiveRecord::Base");
   - repeatedly add the classes in the return types of methods of reachable classes until nothing new is added;
   - computed return types (``…``) are not evaluated by the dump; resolve the ones that occur by name:
     `DBTypes.array_schema(trec)` and `DBTypes.joins_output_type(...)` -> ActiveRecord_Relation (of the receiver's
     model), `DBTypes.rec_to_nominal(trec)` -> the relation's model, Hash#[] `output_type(trec, targs)` -> the
     value types of the reachable hash types. Anything else computed: treat as reaching nothing new, and say so.
   To get the function type and components, change dump_blocked.rb to keep the blocked data at subtract and write the
   JSON (and exit) at SynthesizerProxy#initialize instead, adding "functype" and "components" to the JSON.
2. Computed types. In vanilla, methods with computed types (Hash#[], where, exists?, joins, first on relations) give
   a precise type per receiver/arguments, so each one acts like many narrow signatures; our scrubbed %dyn version
   matches any receiver. Mark each pool entry `"computed": true/false` (true if any of its vanilla types contains
   ``…``) and add a CSV column `added_computed_in_vanilla` for the method added that round.
3. Delete the old trial output before rebuilding: ~/rbsyn_debug_logs/ablation/gitlab_issue_close/ (its pool was
   built without reachability).

Batch plan (do it in this order, few steps):
1. Read the three scripts. Make both changes (reachability in ablate.rb's pool build, dump at SynthesizerProxy, the
   computed flag and column) in one editing step. `ruby -c` both files.
2. Delete the old trial dir. Build the pools for the first three benchmarks in ONE command by running a pool-only
   step for each (add a `--pool-only` flag to ablate.rb that stops after the pool and load check):
   gitlab/issue_close, diaspora/invitation_code_use, synthetic/user_exists.
3. One check: for each, print pool size, the reachable classes, how many entries are computed, and a few scrubbed
   entries. Report to the user and wait for the go-ahead before starting rounds.
4. On go-ahead: run the three ablations one after another in the background in a single command
   (`ruby scripts/ablation/ablate.rb <bench>` for each, sequentially), and report when the task notification arrives.
   Round 0 (no extra methods) must PASS for each; if it does not, report that instead of continuing.

Other fast passing benchmarks for later (dev, INFO_ORDER=off, before today's changes; re-verify): invitation_code_use
1.1 s, clear_global_notice_if_needed 2.3 s, issue_close 1.2 s, issue_reopen 2.8 s, false 0.03 s, lvar 0.03 s, branch
3.3 s, method_chain 1.9 s, user_exists 2.7 s, user_process_invite_acceptence 1.3 s.

Context from today worth knowing (details in docs/ai_fixes_to_review.md and docs/paper_tracking.md): receiver
check fix in InferTypes#w_instrument, dead-call pruning (lib/rbsyn/dead_call_prune.rb), front-of-queue
watermark, ANY wildcards / wrong-key no-go / type-level marker in failure records, CheckErrorPassV2 replacing the
original checker (lib/rbsyn/ast/check_error_pass_v2.rb; original kept, CHECKER=old rolls back). Open question for
the user, not part of this task: turning the older PRUNE_TYPE_ERR rule off by default (it over-drops nil arguments).
