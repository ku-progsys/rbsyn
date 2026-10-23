# Plan: RbSyn as an MCP server / Claude Code plugin (AI generated, 2026-10-19)

Goal: let an AI agent (e.g. Claude Code) **write specs**, **query types** (declared and learned), and **run the
synthesizer in the background**, through a small set of tools.

## What to build

The right shape is an **MCP server** (the tool interface), shipped inside a **Claude Code plugin** (which bundles the
server config plus a skill that teaches the agent how to write RbSyn specs). A plugin alone has no way to run Ruby
searches; an MCP server alone works with any MCP client but doesn't teach spec writing. Both together cover it.

### Tools the server exposes

| Tool | Input | Output |
|---|---|---|
| `validate_spec` | spec (Ruby DSL text) + app name | parses, loads, runs each `setup` once; reports errors |
| `query_types` | class, method (optional) | declared, `%dyn` placeholder, and learned signatures, with effects |
| `infer_types` | spec, budget | runs the inference pass only, returns newly learned signatures |
| `synthesize` | spec, options (timeout, ITERS, flags) | job id (returns immediately) |
| `job_status` / `job_result` / `job_cancel` | job id | state, progress (iteration, learned count), program source, stats |
| `list_apps` / `list_benchmarks` | — | available app environments and example specs |

Resources (read-only): the learned-type store, job logs, the spec DSL reference.

## Steps

1. **Library entry point, separate from minitest.** Today a run is a test file (`describe`/`it`, `define ... do spec ...
   generate_program end`). Add `lib/rbsyn/api.rb` with `RbSyn.run(spec_source, app:, options:)` that returns a result
   object (program, learned types, stats, error) instead of asserting or raising inside a test.
2. **Configuration out of `ENV`.** About 40 behaviours are switched by environment variables (`ADD_DYN`, `ITERS`,
   `INFO_*`, `TIMEOUT`, ...; see `docs/env_flags.md`). Collect them in one options object; keep `ENV` as the default
   source so benchmarks still work. `ADD_DYN` is also flipped *during* a run, so it has to become run state, not
   global state.
3. **One process per job.** RDL's type tables, `ParentsHelper` class variables, `$__` globals, and caches are all
   process-global and mutated during a run. Run every `synthesize`/`infer_types` job in a forked or spawned child
   process; the server process only manages jobs. This also gives clean timeouts (kill the child).
4. **Remove interactive stops.** There are 21 live `binding.pry` calls in `lib/` (error paths in `reachability.rb`,
   `type_ops.rb`, ...). In a headless server they hang the job forever. Replace them with raised errors (or guard them
   behind a debug flag); always run children with stdin closed.
5. **App environments.** Benchmarks run against Rails models and a test database (Diaspora, Discourse, GitLab models,
   `Fabricate`, DB reset between examples). Each app needs a boot script, a database per concurrent job (or job
   serialization per app), and the reset logic that the benchmarks already use.
6. **Learned-type store.** Learned signatures currently live in RDL's in-memory table and die with the process. Write
   them to a file per app (JSON: class, method, args, result, effects, which spec/job learned them) so `query_types`
   can answer from it and later jobs can start from it (optional, switchable, since it changes the experiment).
7. **Job runner.** Queue, concurrency limit, status file per job (iteration count, phase inference/typed, learned
   signatures so far, elapsed time), log capture, cancel. Progress comes from hooks already used by the tracers
   (`trace_learned.rb`, `trace_pop.rb`).
8. **MCP server.** Ruby, using the official `mcp` gem over stdio, so it can call the library directly for cheap tools
   (`query_types`, `validate_spec`) and spawn children for the expensive ones. Each tool gets a JSON schema and short
   descriptions.
9. **Plugin packaging.** A Claude Code plugin with the server config (`.mcp.json`), a skill (`SKILL.md`) that explains
   the spec DSL, `%dyn` declarations, `moi`, effects annotations and good-spec habits, plus a few example specs.
10. **Tests.** Run the 18 shared benchmarks through the API and check results match the test-file runs; a test that a
    cancelled/timed-out job leaves no child process behind.

Rough order: 1, 2, 3, 4 (the library becomes usable headless) → 7, 8 (server) → 5, 6 (apps, store) → 9, 10.

## Pros

- **Agent writes the specs.** Writing specs (setup + assertions) from existing tests is the main human cost of using
  RbSyn; an agent that already reads the codebase can do it, and `validate_spec` gives it a fast check.
- **Type queries are useful on their own.** Learned signatures for `%dyn` methods are information an agent normally
  doesn't have (what a dynamic method actually takes and returns at runtime).
- **Division of labour.** The agent handles intent and spec writing; the synthesizer does the exhaustive, checkable
  search, and its output is verified against the spec rather than guessed.
- **Background jobs fit the runtime.** Runs take seconds to minutes; jobs with status let the agent keep working.
- **Research value.** An "agent + synthesizer" setting is a natural extra experiment, and the job runner makes
  benchmark runs scripted and reproducible.

## Cons

- **Refactoring cost now.** Steps 1-4 touch the code while it is still changing for the paper; risk of new bugs in
  the search itself. Best done after the paper's experiments are frozen.
- **Global state.** The process-per-job rule is mandatory, which makes cheap repeated calls (e.g. many `infer_types`
  on one app) slow because each pays Rails boot time (seconds).
- **Arbitrary code execution.** Specs are Ruby; `setup` blocks and synthesized programs run with full access. Needs a
  sandbox (container, separate DB user) before it is exposed beyond a local machine.
- **App coupling.** Every target app needs its own boot script, models, fixtures and DB; it doesn't work on an
  arbitrary Ruby project out of the box.
- **Spec quality decides results.** Weak assertions give wrong-but-passing programs; the agent needs guidance (the
  skill) and the result should show which assertions constrained it.
- **Paper confound.** If the agent writes specs or reuses learned types across jobs, results are no longer comparable
  with the benchmark setting; keep these as separate, clearly labelled experiments.
