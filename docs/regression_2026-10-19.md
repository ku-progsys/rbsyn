# Regression run, 2026-10-19 (AI generated)

Code: dirtycode working tree with this session's changes. Logs: `~/rbsyn_debug_logs/bench_dev_regress_1019`
(run 1), `bench_dev_regress_1019_noorder` (run 2), `bench_long_prof_1019` (run 3). Times are the test's own time;
runs 1-2 ran 8 in parallel, run 3 ran 6 in parallel (15 GB machine). Vanilla numbers are the old ones, not re-run.

- Run 1: defaults (information ordering on), TIMEOUT 300.
- Run 2: same, `INFO_ORDER=off` (size ordering during inference).
- Run 3: benchmarks vanilla passes and dev fails, ordering on, `ITERS=50 TIMEOUT=600`, with stackprof.

| Benchmark | Vanilla | Dev run 1 (order on) | Dev run 2 (order off) | Run 3 (long, order on) |
|---|---|---|---|---|
| invitation_code_use | 0.07s | crash, my Float bug, **fixed** (passes after fix) | 1.12s | – |
| user_confirm_email | 3.27s | timeout | 136.50s | – |
| clear_global_notice_if_needed | fail | 116.09s | 2.28s | – |
| issue_close | 1.13s | 24.94s | 1.19s | – |
| issue_reopen | 90.35s | timeout | 2.83s | – |
| false | 0.12s | 0.04s | 0.03s | – |
| lvar | 0.13s | 0.04s | 0.03s | – |
| branch | 13.68s | No candidates | 3.31s | – |
| method_chain | 11.70s | No candidates | 1.93s | – |
| user_exists | 10.98s | timeout | 2.69s | – |
| pod_schedule_check_if_needed | 100s | killed (out of memory) | timeout | killed (out of memory) |
| unstage_user | 24.8s | killed (out of memory) | timeout | killed (out of memory) |
| overview_example | 2.67s | killed (out of memory) | timeout | killed (out of memory) |
| check_site_contact_username | 148s | timeout | timeout | timeout 600s (97% of time in GC) |
| discussion_build | 0.23s | No candidates | No candidates | timeout 600s (needed types learned; 222 iterations) |
| activate | 44.8s | timeout | No candidates | killed (out of memory) |
| merge | fail | timeout | killed (out of memory) | – |
| user_process_invite_acceptence | 4.11s | **error** (below) | **error** | not run |

## Errors (benchmarks that do not run)

| Benchmark | Error | Status |
|---|---|---|
| user_process_invite_acceptence | `NoMethodError: undefined method '[]' for nil` at `lib/rbsyn/ast/expand_hole_pass.rb:370` (`fn_call`) | known (bug 4 in `open_bugs.md`), not investigated |
| invitation_code_use (run 1 only) | `RDL::Type::TypeError: Integer#-` from `InferTypes#binary_entropy` (`1 - q` with Float q, RDL wraps `Integer#-`) | fixed: Float-only arithmetic in the scorer |

## Findings

1. **The information ordering causes all 5 regressions** (user_confirm_email, issue_reopen, branch, method_chain,
   user_exists). With `INFO_ORDER=off` all of them pass, as before this session. Bisect on method_chain: turning off
   any single new piece (depth cap, hole P, seen subexpressions, occ_m, `%dyn` receivers, methods_of cache, size
   penalty) does not fix it; only `INFO_ORDER=off` does. Cause (method_chain): the needed `User.exists?(username: arg0)`
   candidates are generated but never popped, because P is per method and `exists?` was already tested with String
   arguments. P cannot tell that a hash argument is a new argument type. Suggested fix (not implemented): P = 1 for an
   untested (receiver type, method, argument types) combination.
2. **Memory.** Single runs reach 5-6.6 GB RSS (kernel OOM log), so parallel runs on this 15 GB machine get killed.
   check_site_contact_username spends 97% of its time in garbage collection after iteration 19. The work list holds
   tens of thousands of candidates, each with its own AST copy.
3. **discussion_build** learns both needed signatures early (iteration 77) but needs > 600s for 500 inference
   iterations; speed (root cause B) is now the limit. Profile: building candidates 42%, sorting 18%, `methods_of` copy
   13%, type checking 8%, GC 28%.
4. **Ordering-on runs are slower even when they pass** (issue_close 24.9s vs 1.2s, clear_global_notice 116s vs 2.3s).

## Profiles

Usable: `bench_long_prof_1019/gitlab_discussion_build.dump.16641`,
`discourse_check_site_contact_username.dump.16639`. The out-of-memory kills lost the other profiles (stackprof writes
at exit).

## Update 2026-10-20 (AI generated)

overview_example memory blow-up found and fixed (details: `ai_fixes_to_review.md`, 2026-10-20): RDL hash-type bounds
grown by our error checks, multiplied by the Marshal deep copy in `fn_call`. With the fix (ordering off) peak memory is
281 MB instead of 5-10 GB; the benchmark now times out at 300 s instead of being killed. The same mechanism may be
behind the other out-of-memory kills (pod_schedule_check_if_needed, unstage_user, activate): not yet rerun.

Recheck of the out-of-memory benchmarks with the fix, defaults (ordering on), TIMEOUT=300, one at a time
(logs: `~/rbsyn_debug_logs/oom_recheck_1020`):

| Benchmark | Before (run 1) | Now | Peak memory | Where the time goes |
|---|---|---|---|---|
| pod_schedule_check_if_needed | killed (OOM) | timeout | 3.3 GB | inference 242 s of 300 (171 iterations); work list 31,885 |
| unstage_user | killed (OOM) | timeout | 3.6 GB | inference (228 iterations) not finished at 300 s |
| activate | killed (OOM, run 3) | `No candidates found` at 76 s | 1.1 GB | inference 76 s, then typed search exhausted (needed signatures not learned) |
| overview_example (ordering off) | killed (OOM) | timeout | 0.28 GB | inference 115 s, typed search 185 s without a solution |
