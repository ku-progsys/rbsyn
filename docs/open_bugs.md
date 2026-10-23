# Open bugs (dev branch, %dyn conversion) — as of 2026-10-12

| # | Bug | Where / symptom | Notes |
|---|-----|-----------------|-------|
| 1 | ~~RefineTypesV2 lost nested refined types~~ | refine_types_v2.rb | FIXED 2026-10-12 (old behaviour behind REFINE_KEEP_OLD=1) |
| 2 | `EffectAnalysis.type_of` crashes on a method with no known type | effects.rb (`[TY]` trace); e.g. `!` on a nil-typed `scheduled_check` (pod_schedule_check_if_needed) | proposed: treat unknown method type as %dyn |
| 3 | Only one `hashkeys` component per benchmark | spec/ParentsHelper | benchmarks with two models only get one model's columns |
| 4 | ~~user_process_invite_acceptence crashes~~ | expand_hole_pass.rb `fn_call`, `info[:type]` on nil during effect search | FIXED 2026-10-19: `methods_with_write_effect` offered `%dyn` placeholder methods in the typed search, which `methods_of` does not; now only during inference. PASS 1.37s (order off), 4.23s (order on) |
| 5 | activate: no candidates | inference ends after 0.2s, then work list empties | unexplained |
| 6 | merge: no candidates after ~7s | | unexplained (vanilla also times out on merge) |
| 7 | discussion_build: no candidates | setters never tried on a GitlabDiscussion | unexplained |
| 8 | Class methods from `extend`ed modules not searched | | known limitation |
| 9 | Setter chosen as branch condition | | ignore for now |
| 10 | ~~method_chain:~~ FIXED 2026-10-13 (`!` visible during condition search, see syn_helper `with_condition_terms`; PASS 1.4s) — no candidates after ~76s (full run, 2026-10-12) | branch search, spec 1 | DIAGNOSED 2026-10-13: `!` on a boolean is never learned. Inference budget (19 x #moi = 38) runs out before a nested `(X.exists?(..)).!` or `(!arg0).!` is ever run. ITERS=60 not enough; ITERS=200 learns it and finds vanilla's branches (`!!arg0`, `User.exists?(username: arg0)`) in ~3s, then the merge step times out (see 12) |
| 11 | ~~user_exists:~~ FIXED 2026-10-13 (same fix, no spec edit needed; PASS 2.1s) — no candidates after ~67s (full run, 2026-10-12) | branch search, spec 1 | DIAGNOSED 2026-10-13: conversion gap. Vanilla's branch for spec 1 is `!!arg0`, but `!` isn't in the window/moi (rule only took methods from the final solution, not branch conditions). Also needs `!` on a boolean (see 10) |
| 12 | method_chain merge step times out (NOT REPRODUCED with the `!` fix at default budget; only seen with ITERS=200) | merge condition search after per-spec programs `true`/`false` | seen only with ITERS=200; typed search hit 400 iterations, then inference pass, then timeout. Vanilla merges to `!User.exists?(username: arg0)` |

## Full-run results, dev (minimal %dyn set) vs vanilla — 2026-10-13
Wall-clock times per benchmark file; dev timeouts are the synthesizer's own 300s limit.

| Benchmark | Dev | Vanilla |
|---|---|---|
| user_confirm_email | PASS (~80s per run) | PASS 14s |
| method_chain | ERROR no candidates (76s) | PASS 38s |
| user_exists | ERROR no candidates (67s) | PASS 36s |
| pod_schedule_check_if_needed | TIMEOUT 300s | PASS 278s |
| check_site_contact_username | TIMEOUT 300s | PASS 388s |
| unstage_user | TIMEOUT 300s | PASS 84s |
| branch | TIMEOUT 300s | PASS 45s |
| overview_example | TIMEOUT 300s | PASS 12s |

## The 5 timeouts, rechecked with the `!` fix — 2026-10-13
| Benchmark | Result | Where it stalls | Classification |
|---|---|---|---|
| branch | PASS 3s | — | SOLVED by `!` in condition search |
| check_site_contact_username | timeout (also at 900s) | spec 3's branch-search inference pass (152 iterations) ran 13+ min without finishing | REAL (performance), probably the same slow inference loop as overview_example; not yet confirmed with DBG_DYN |
| pod_schedule_check_if_needed | timeout (also at 900s) | merge condition 1 typed search after inference, 15+ min | REAL: vanilla's condition `arg0.status != DiasporaPod.status_codes[:unchecked]` needs `Hash#[](Symbol)` and `Integer#!=`, never learned (both receivers are call results); same nested-call limit |
| unstage_user | timeout | spec 1 typed search after 4s inference | REAL: setters (`username=`, `name=`, `active=`) never learned on an AnotherUser instance; receiver must come from a call (`AnotherUser.where(..).first`), same nested-call limit as item 10 |
| overview_example | timeout | spec 1 inference pass never finishes (~125 of 209 iterations in 60s, ~2s/iteration and growing) | REAL (performance): every new success/error rescores the whole work list (~2000 candidates) with check_errors (syn_helper.rb ~401); eval is the other half |

## Remaining 5 failures diagnosed with the learned-type tracer — 2026-10-13
| Benchmark | Result | Types vanilla's program needs that were NOT learned | Classification |
|---|---|---|---|
| discussion_build | no candidates, 2.5s | `notes=`, `noteable_id=` on a GitlabDiscussion instance (`GitlabDiscussion.new` and `#save` on it were learned) | ROOT CAUSE A |
| activate | no candidates, 4.7s | `first` on the `email_tokens` collection, `token` on an EmailToken, `EmailToken.confirm` | ROOT CAUSE A |
| merge | timeout (vanilla also times out) | `exists?` on the result of `User.joins(..)` (only learned on the classes, String args) | ROOT CAUSE A |
| user_process_invite_acceptence | crash, 1.5s (`[]` for nil, item 4) | none: `invited_by_id=`, `diaspora_user_id`, `synth_use!` all learned | REAL BUG (crash), not A |
| check_site_contact_username | timeout at 300s | none: `admin`, `moderator`, `set_and_log`, `defaults`, `Hash#[](Symbol)`, `!` on booleans all learned | SPEED (root cause B / search), not A |

Totals over the 18 comparable shared benchmarks (vanilla skips 3 of the 21): 10 pass; root cause A 6 (pod_schedule_check_if_needed,
unstage_user, overview_example, discussion_build, activate, merge); crash 1 (user_process_invite_acceptence); speed 1 (check_site_contact_username).

## 2026-10-19: information ordering regresses method_chain (and possibly others)
`method_chain` needs `!User.exists?(username: arg0)`. With `INFO_ORDER=off` it passes (1.65s); with the information
ordering it ends with "No candidates" (inference budget 38). The hash-argument candidates are generated but never
popped: P is per method, `exists?` was already tested with String arguments that revealed nothing new, so its P is
low, while holes and `!` chains score higher. P cannot tell that a new argument type (a hash) is untested.
Candidate fix (not implemented, discuss): P = 1 for a call whose (receiver type, method, argument types) combination
has not been tested yet, using the static types of the arguments.
