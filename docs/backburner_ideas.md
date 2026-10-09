# Backburner ideas (not implemented)

*AI generated note, 2026-10-09, from discussion with the user.*

## 1. Per-moi "temperature" for search ordering

For each method of interest, keep running counts over the inference runs that exercised it with `%dyn` types:
how many returned a **new type hit** (a success with a new signature) and how many a **bad type hit** (a new
recorded error). Use the ratio as a weight per moi (a histogram over moi) in search ordering, so candidates
exercising methods that are still yielding new types are preferred, and methods that have stopped yielding
anything new are de-prioritised.

Motivation: in the confirm_email benchmark, `exists?` was never exercised by any inference pass (budget went to
setters and `!=` hash variants that kept yielding near-duplicate signatures), so the merge step had no
`exists?` signature to build its separating condition from.

## 2. Decay rate for inference budgets

From the first inference run, estimate how fast new types / bad types are being learned (new hits per iteration
over time, i.e. a decay rate). Use it to judge how long a later inference pass should run before it is unlikely
to find anything new, instead of a fixed `moi.size * ITERS` iteration budget.
