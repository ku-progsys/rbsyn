# Instrumentation: known semantic differences (logged for later)

*AI generated note, 2026-10-07.* Inference runs (`eval_ast_second`) rewrite calls to methods of interest
(`moi`) as `@dummyclass.w_instrument(recv, :meth, *args)` (`TrackerRewrite` in
`lib/rbsyn/ast/track_rewrite.rb`, `InferTypes#w_instrument` in `lib/rbsyn/ast/infer_types.rb`).
That call does `recvr.send(meth, *args)`, which differs from an ordinary Ruby call in the cases below.
None of them is triggered by the programs the synthesizer currently generates; they are recorded so
they can be fixed when they come up. Fixes would stay inside the current design (extend
`w_instrument`), see the last section.

| # | Case | Normal Ruby | Under `w_instrument` | Triggered today? |
|---|------|-------------|----------------------|------------------|
| 1 | Setter used as a value, e.g. `(x.y = v) != z` or a setter as a branch condition | expression value is `v` | value is the setter method's return value | Yes, but ActiveRecord attribute writers return the value passed, so results match |
| 2 | Call with a block, `x.m { ... }` / `x.m(&b)` | block passed to `m` | block passed to `w_instrument`, not forwarded (no `&blk`) | No |
| 3 | Keyword arguments, `x.m(k: 1)` | passed as keywords | collected by `*args` and passed as a positional Hash (Ruby 3 keyword separation) | No (`exists?` takes a positional hash) |
| 4 | Private method with an explicit receiver | `NoMethodError` | succeeds (`send` ignores visibility) | Only if reachability offers a private method |
| 5 | Call without an explicit receiver, `foo(x)` | `self.foo(x)` | receiver child is `nil`, becomes `nil.foo(x)` | No (candidates always have a receiver) |
| 6 | Wrapped calls under `&&`, `\|\|`, `if`, loops, or executed repeatedly | — | tracelist slots are matched by execution order (`@counter`) and consumed (`argtypes.shift`), so skipped or repeated calls misalign later slots | No |
| 7 | Exceptions | original exception class | some `NoMethodError`/`NameError` are re-raised as `ComplexError`, which inherits from `Exception`, so `rescue StandardError` misses them | `generate` rescues both the same way |
| 8 | Lazy results | not forced | `result.inspect` is always called (deliberate: catches Hamster lazy-list errors), which forces laziness and runs `inspect` side effects | Yes, by design |

## Related: lossy source round trip

`Parser::CurrentRuby` here is `Parser::Ruby27` (parser gem 2.7.2) while code runs on Ruby 3.2. Parsing
and re-printing with Unparser loses distinctions Ruby 3.2 cares about:

- `m(k: 1)` and `m({k: 1})` parse to the same tree; Unparser prints `m(k: 1)` (keywords vs positional hash).
- `x.m { |a| a }` prints as `x.m { |a,| a }` (`|a,|` destructures an array argument; `|a|` does not).

Synthesized programs are unaffected (both their normal and instrumented runs go through Unparser).
`InstrumentedAssertions` (`lib/rbsyn/instrumented_assertions.rb`) guards against this by only
instrumenting assertions that contain none of these constructs and otherwise running them unchanged.

## If these need fixing

Keep the current design and extend `w_instrument`: accept and forward `**kw, &blk`; return the assigned
value for setter names; use `public_send` for explicit receivers and pass `self` for implicit ones;
pass the call-site index into `w_instrument` instead of using `@counter`, and read tracelist entries
without consuming them; re-raise the original exception while recording the `ComplexError` details.
For source that must not round-trip, rewrite the original text with `Parser::Source::TreeRewriter`
instead of parse/print.
