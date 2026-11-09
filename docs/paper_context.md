# Paper writing context (2026-11-08)

Draft: `C:\Users\Bryan R\Desktop\ReflectionsAndResearch\MyPaper.md`, bibliography `references.bib` next to it
(rbsyn, apiphany). Abstract, introduction and background are drafted; formalism, implementation, methodology and
conclusion are empty.

## Open code work before final numbers

From `docs/todos.md`, in order: `wrap: false` in `register_learned`; modular error handlers; collapse
`RefineTypesV2` and `CheckErrorPassV2`; update concretized programs after execution only when a new type is found;
separate collection from computation in `InferTypes`. Any of these that changes search timing means re-running the
MOI ablation and the fully-typed comparison, on one machine (`docs/paper_tracking.md`).

## Draft claims to check against the code

| Draft says | Code today |
|---|---|
| "inferred types persist beyond the synthesis session" | Learned types live in RDL's in-memory tables and are lost when the process ends. Persisting them is planned only (`docs/mcp_plan.md`, step 6). |
| "stripped of all annotations" | Methods keep their arity and read/write effects as `%dyn` placeholders inside the `init_list`..`subtract()` window. `!` is visible during condition search (list B). |
| "naively enumerate" | Enumeration is ordered and pruned: dead-call pruning, hole depth cap, `%dyn` argument exhaustion, spec type guard (all in `docs/paper_tracking.md` list B or the inference-only list). |
| "type-collection pass once per specification, then a fresh pass with discovered types as ground truth" | Matches the default path. Exceptions: the spec type guard skips inference for some specs, and merge conditions run typed first, then inference after 190 iterations. |
| Outcome 2: "the offending type signature is recorded as a failure" | Failures are recorded with refinements: `:ALL` (method missing on the receiver), `ANY` wildcards for unblamed arguments, wrong-key no-go, type-level marking. |
| APIphany "learns from pre-collected traces" | Correct, with nuance: APIphany does execute API calls before synthesis (random testing alternating with type mining), keeps only successful calls, and infers types from equal values at different locations. It never asks the runtime for a value's type; we read `x.class` directly. |

## How the extension works (for Implementation)

- Specs declare the methods of interest (moi) as `%dyn` signatures with effects. `ParentsHelper.subtract()` blocks
  every signature declared before the window.
- `TrackRewrite` wraps each moi call in `InferTypes#w_instrument`, which runs the call and records a trace: receiver,
  argument and result types from the runtime (`x.class`), or the exception.
- Successes are merged into the most general comparable signature and registered in RDL under the receiver's class,
  carrying the declared effects. Failures are merged and refined as above.
- Candidates are scored by `CheckErrorPassV2` (inferred errors, remaining `%dyn` parts) and sorted. Type-level and
  method-missing failures drop candidates (`DeadCallPrune`), and successes always override failures.
- The inference budget is `ITERS` (default 19) times the number of moi. After it runs out, the search continues typed.

## Results available now

MOI ablation, 2026-10-23, commit 4c15a41, seed 1, 1200 s per round, one method added per round
(`ablation_results/`):

| Benchmark | Pool | Max added and passing | End | Time at 0 added | Time at last pass |
|---|---|---|---|---|---|
| diaspora/invitation_code_use | 29 | 29 | pool exhausted | 0.67 s | 42.20 s |
| diaspora/user_process_invite_acceptence | 27 | 9 | TIMEOUT at 10 | 0.79 s | 8.75 s |
| discourse/clear_global_notice_if_needed | 38 | 38 | pool exhausted | 1.20 s | 87.18 s |
| gitlab/issue_close | 27 | 27 | pool exhausted | 0.66 s | 35.71 s |
| gitlab/issue_reopen | 26 | 26 | pool exhausted | 1.38 s | 12.83 s |
| synthetic/branch | 41 | 41 | pool exhausted | 2.67 s | 21.95 s |
| synthetic/method_chain | 41 | 41 | pool exhausted | 1.05 s | 12.42 s |
| synthetic/user_exists | 42 | 42 | pool exhausted | 1.55 s | 12.64 s |
| synthetic/false | 43 | 0 | NO_CANDIDATES at 1 | 0.02 s | 0.02 s |
| synthetic/lvar | 43 | 0 | NO_CANDIDATES at 1 | 0.03 s | 0.03 s |

- Reproducibility: the slowest round of three benchmarks gave identical learned and rejected type sets on a second
  machine, at about 1.3x the time. Don't mix times across machines.
- These times predate the information-ordering removal (about 4-14% faster), so they need re-running.
- Solved counts for the abstract's "X of N vs Y of N" are stale: the last full comparison is 2026-10-13
  (`docs/open_bugs.md`: 18 comparable shared benchmarks, 10 passing in dev at that time). A fresh full run is needed.
- Overloads: learned methods often end up with several signatures (e.g. `User#active=` with 8, all with different
  results), which is relevant to the draft's "several signatures per method" point.

## Known limits (for Discussion)

- Lazy evaluation: an error can surface later than the call that caused it (`whereIleftoff.md`, Hamster `take`).
- Effects that change a method's signature are not modeled (parked).
- `true` and `false` are recorded as one type, so a failure on one covers the other.
- Bootstrapping: a method on type T is only learned once some program produces a T, so methods on call results are
  learned late.
- Refine picks the first of several overloaded signatures (fixed by the planned collapse).
- Permissive setters and loose specs: inference learns any signature that runs without an error. ActiveRecord setters
  convert values silently (`issue.state_id = true` stores 1; `issue.closed_at = true` keeps `true`) and nothing raises
  until a save, so `issue_close` learns `state_id=(true or false)` and `closed_at=(true or false)`. Its spec only checks
  `state_id == 1` and `closed_at != nil`, so `arg0.state_id = true; arg0.closed_at = true` passes, in the typed pass
  too (seen before 2026-11-08 changes, run do_base_1108). Fully-typed rejects it (`Integer`, `Time` arguments).
