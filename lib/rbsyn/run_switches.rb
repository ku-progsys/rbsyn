# AI generated (2026-10-20): run switches, set before every run (loaded first by lib/rbsyn.rb).
#
# Edit the values here instead of typing them on the command line. A variable already set in the environment wins,
# so a one-off run can still override a value (e.g. `WATERMARK=all bundle exec rake ...`).
# The values below are the current defaults; the comment says what the other value does.
RUN_SWITCHES = {
  # exhaustion watermark: "front" = smallest size among the candidates with the fewest inferred errors;
  # "all" = smallest size in the whole work list (previous behaviour)
  "WATERMARK" => "front",

  # RefineTypesV3 (lib/rbsyn/ast/refine_types_v3.rb): "on" drops a program at its first failing call, as a prune;
  # "off" keeps it, counts every failing call and carries on with the failed call's stored type
  "AGGRESSIVE_PRUNING" => "off",

  # inference budget of each spec after the first (lib/rbsyn/synthesizer.rb): the previous budget divided by this
  # ("2" = halving, "4" = quartering)
  "INFER_DECAY" => "2",

  # failure records (lib/rbsyn/ast/infer_types.rb): "on" / "off"
  "ERR_ANY_POS" => "on",        # one blamed argument: other positions become ANY
  "ERR_ANY_KEY" => "on",        # one blamed key in a hash argument: other keys become ANY
  "ERR_KEY_NOGO" => "on",       # wrong-key error: that key with any value is a no-go
  "ERR_TYPE_LEVEL" => "on",     # mark type-level failures (:type_except); an exact match on one prunes
}.freeze

RUN_SWITCHES.each { |name, value| ENV[name] = value unless ENV.key?(name) }
