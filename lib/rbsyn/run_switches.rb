# AI generated (2026-10-20): run switches, set before every run (loaded first by lib/rbsyn.rb).
#
# Edit the values here instead of typing them on the command line. A variable already set in the environment wins,
# so a one-off run can still override a value (e.g. `PRUNE_CHECK=off bundle exec rake ...`).
# The values below are the current defaults; the comment says what the other value does.
RUN_SWITCHES = {
  # search order during inference: "off" = order by size (best so far); remove the line for information ordering
  "INFO_ORDER" => "off",

  # failure checker: "new" = CheckErrorPassV2 (lib/rbsyn/ast/check_error_pass_v2.rb); "old" = original CheckErrorPass
  "CHECKER" => "new",

  # exhaustion watermark: "front" = smallest size among the candidates with the fewest inferred errors;
  # "all" = smallest size in the whole work list (previous behaviour)
  "WATERMARK" => "front",

  # dead-candidate pruning (lib/rbsyn/dead_call_prune.rb): "on" / "off"
  "PRUNE" => "on",              # "off" turns every pruning rule off
  "PRUNE_DEAD_LITERAL" => "on", # method missing on a literal receiver
  "PRUNE_DEAD_VAR" => "on",     # method missing on a known-type variable receiver
  "PRUNE_TYPE_ERR" => "on",     # own matching of type-level failures (no nil carve-out; PRUNE_CHECK covers it)
  "PRUNE_CHECK" => "on",        # CheckErrorPassV2 reports a drop

  # failure records (lib/rbsyn/ast/infer_types.rb): "on" / "off"
  "ERR_ANY_POS" => "on",        # one blamed argument: other positions become ANY
  "ERR_ANY_KEY" => "on",        # one blamed key in a hash argument: other keys become ANY
  "ERR_KEY_NOGO" => "on",       # wrong-key error: that key with any value is a no-go
  "ERR_TYPE_LEVEL" => "on",     # mark type-level failures (:type_except), used by the pruning rules
}.freeze

RUN_SWITCHES.each { |name, value| ENV[name] = value unless ENV.key?(name) }
