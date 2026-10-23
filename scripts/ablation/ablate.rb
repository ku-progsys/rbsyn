#!/usr/bin/env ruby
# AI generated (2026-10-20): methods-of-interest ablation for ONE benchmark, with a checkpoint and one CSV.
#
# usage: ruby scripts/ablation/ablate.rb <benchmark, e.g. gitlab/issue_close> [limit_seconds=1200] [seed=1] [--pool-only]
#   --pool-only: stop after the pool and its load check (writes the checkpoint; rerun without it to start rounds) [--pool-only]
#
# 1. Pool (once): dumps every signature the benchmark had before its %dyn window (ParentsHelper.blocked), keeps those
#    on vanilla-reachable classes (reach.json: from the define's type and components; see below), scrubs each
#    restricted to the classes vanilla can reach (see reachable below) into a %dyn declaration the way the benchmarks were converted (same argument count, all types %dyn, effects on
#    the method's own class -> 'self', other effects reduced to their class), drops duplicates and names the window
#    already declares, shuffles with the seed, and checks that all of them load (one short run).
# 2. Rounds: round r adds the first r pool methods (declaration + method of interest) to the benchmark and runs it
#    with the time limit. One CSV row per round. Stops at the first round that does not solve in time.
# Checkpoint: <out>/checkpoint.json holds the order and the next round; rerunning the same command resumes there.
# Only one ablation runs at a time (lock file); quiet runs (no debug logging, no profiling).
require "json"
require "csv"
require "fileutils"

pool_only = !ARGV.delete("--pool-only").nil?
bench = ARGV[0] or abort "usage: ablate.rb <benchmark> [limit_seconds] [seed] [--pool-only]"
limit = (ARGV[1] || 1200).to_i
seed = (ARGV[2] || 1).to_i
root = File.expand_path("../..", __dir__)
out = File.join(ENV["ABLATE_DIR"] || File.expand_path("~/rbsyn_debug_logs/ablation"), bench.tr("/", "_"))
FileUtils.mkdir_p(out)
test_file = "test/benchmark/#{bench}_benchmark.rb"
abort "no such benchmark: #{test_file}" unless File.exist?(File.join(root, test_file))

# --pool-only builds take a per-benchmark lock, so they can run beside a round run of another benchmark
lock = File.open(pool_only ? File.join(out, ".pool.lock") : File.join(File.dirname(out), ".ablation.lock"), File::RDWR | File::CREAT)
abort "another ablation is running (#{lock.path})" unless lock.flock(File::LOCK_EX | File::LOCK_NB)

def run_rake(root, test_file, env, limit, log)
  cmd = ["timeout", "-s", "KILL", (limit + 120).to_s, "bundle", "exec", "rake", "TEST=#{test_file}"]
  pid = Process.spawn(env, *cmd, chdir: root, out: log, err: [:child, :out], in: "/dev/null")
  Process.wait(pid)
  # timeout -s KILL on rake can leave the test process behind
  system("pkill", "-9", "-f", "bin/ruby .*rake_test_loader.rb #{test_file}", out: File::NULL, err: File::NULL)
end

ckpt_path = File.join(out, "checkpoint.json")
pool_path = File.join(out, "pool.json")
csv_path = File.join(out, "#{bench.tr('/', '_')}.csv")

unless File.exist?(ckpt_path)
  # --- 1. pool ---
  dump = File.join(out, "dump.json")
  run_rake(root, test_file, { "ABLATE_DUMP" => dump, "RUBYOPT" => "-r#{root}/scripts/ablation/dump_blocked.rb" }, 120, File.join(out, "dump.log"))
  abort "dump failed, see #{out}/dump.log" unless File.exist?(dump)
  d = JSON.parse(File.read(dump))
  abort "dump has no subtract data (no %dyn window?), see #{out}/dump.log" unless d["subtract_seen"]
  window_names = d["window"].keys
  blocked = d["blocked"]
  # vanilla-reachable classes: the define's type and components, closed under ancestors in the dump and the classes in
  # return types of methods of reachable classes. Computed return types are resolved by name; others reach nothing.
  reach = d["start"].dup
  hash_vals = d["start_hash_vals"].dup
  unresolved = d["start_computed"].map { |c| "functype: #{c}" }
  anc = d["ancestors_all"]
  is_model = lambda { |x| x != "ActiveRecord::Base" && (anc[x] || []).include?("ActiveRecord::Base") }
  loop do
    before = [reach.size, hash_vals.size]
    reach.dup.each { |k| (anc[k] || []).each { |a| reach << a if blocked.key?(a) } }
    reach.uniq!
    reach.dup.each { |k|
      (blocked.dig(k, "methods") || {}).each { |meth, v|
        reach.concat(v["rets"]); hash_vals.concat(v["hash_vals"])
        v["computed_rets"].each { |code|
          case code
          when /DBTypes\.array_schema\(|DBTypes\.joins_output_type\(/ then reach << "ActiveRecord_Relation"
          when /DBTypes\.rec_to_nominal\(/ then reach.concat(reach.select { |x| x.start_with?("[s]") && is_model.(x[3..]) }.map { |x| x[3..] })
          when /\Aoutput_type\(trec, targs\)\z/ then reach.concat(hash_vals)
          else unresolved << "#{k}##{meth}: #{code}"
          end
        }
      }
    }
    reach.uniq!; hash_vals.uniq!
    break if [reach.size, hash_vals.size] == before
  end
  unresolved.uniq!
  File.write(File.join(out, "reach.json"), JSON.pretty_generate({ "functype" => d["functype"], "components" => d["components"],
    "reachable" => reach.select { |k| blocked.key?(k) }.sort, "reachable_not_in_dump" => (reach - blocked.keys).sort,
    "hash_vals" => hash_vals.sort, "unresolved_computed" => unresolved }))
  scrub_effects = lambda { |labels, owner|
    next nil if labels.nil? || labels.empty?
    labels.map { |l|
      cls = l.split(".").first
      l == "*" ? "*" : (owner && cls == owner ? "self" : cls)
    }.uniq
  }
  pool = {}
  blocked.each { |klass, info|
    next unless reach.include?(klass)
    class_method = klass.start_with?("[s]")
    owner = class_method ? nil : klass
    info["methods"].each { |meth, v|
      name = class_method ? "self.#{meth}" : meth
      next if window_names.include?(name)
      v["args"].map(&:size).uniq.each { |n|
        decl = { "name" => name, "args" => n, "read" => scrub_effects.(v["read"], owner), "write" => scrub_effects.(v["write"], owner) }
        key = decl.to_json
        e = (pool[key] ||= decl.merge("from" => [], "computed" => false))
        e["from"] << klass
        e["computed"] ||= v["computed"]
      }
    }
  }
  pool = pool.values.sort_by { |x| [x["name"], x["args"]] }.shuffle(random: Random.new(seed))
  File.write(pool_path, JSON.pretty_generate(pool))
  # check that every scrubbed declaration loads
  round_file = File.join(out, "check_round.json")
  File.write(round_file, JSON.generate({ "decls" => pool, "moi" => [] }))
  check_log = File.join(out, "check.log")
  run_rake(root, test_file, { "ABLATE_ROUND" => round_file, "ABLATE_OUT" => File.join(out, "check_out.json"), "ABLATE_CHECK" => "1",
                              "RUBYOPT" => "-r#{root}/scripts/ablation/hook.rb" }, 120, check_log)
  abort "pool declarations did not load, see #{check_log}" unless File.read(check_log).include?("[ABLATE_CHECK]")
  File.write(ckpt_path, JSON.pretty_generate({ "benchmark" => bench, "seed" => seed, "limit" => limit,
                                               "order" => pool.map { |x| x["name"] }, "next_round" => 0, "done" => false }))
  CSV.open(csv_path, "w") { |c|
    c << %w[benchmark round n_added added_moi added_computed_in_vanilla result solve_time_s types_learned types_rejected_hard types_rejected_soft moi_available]
  }
  puts "pool: #{pool.size} scrubbed signatures on #{(reach & blocked.keys).size} reachable classes (#{window_names.size} already in the window), all load"
end
exit 0 if pool_only

ckpt = JSON.parse(File.read(ckpt_path))
pool = JSON.parse(File.read(pool_path))
abort "#{bench}: already done (#{ckpt['stop_reason']})" if ckpt["done"]

# --- 2. rounds ---
r = ckpt["next_round"]
loop do
  if r > pool.size
    ckpt.merge!("done" => true, "stop_reason" => "pool exhausted")
    break
  end
  extra = pool.first(r)
  round_file = File.join(out, "round_#{r}.json")
  round_out = File.join(out, "round_#{r}_out.json")
  log = File.join(out, "round_#{r}.log")
  File.write(round_file, JSON.generate({ "decls" => extra, "moi" => extra.map { |x| x["name"].sub(/\Aself\./, "") } }))
  File.delete(round_out) if File.exist?(round_out)
  run_rake(root, test_file, { "ABLATE_ROUND" => round_file, "ABLATE_OUT" => round_out, "TIMEOUT" => limit.to_s,
                              "RUBYOPT" => "-r#{root}/scripts/ablation/hook.rb" }, limit, log)
  text = File.read(log).gsub(/\e\[[0-9;]*m/, "")
  line = text[/^\s+test_\d+.*?(PASS|ERROR|FAIL|SKIP) \(([\d.]+)s\)/]
  status, secs = $1, $2
  result = if status == "PASS" then "PASS"
           elsif text.include?("Timeout::Error") then "TIMEOUT"
           elsif text.include?("No candidates found") then "NO_CANDIDATES"
           elsif status then status
           else "NO_RESULT"
           end
  o = File.exist?(round_out) ? JSON.parse(File.read(round_out)) : {}
  CSV.open(csv_path, "a") { |c|
    c << [bench, r, extra.size, extra.last&.fetch("name"), extra.last&.fetch("computed"), result, (result == "PASS" ? secs : nil),
          (o["learned"] || []).join(" | "), (o["rejected_hard"] || []).join(" | "), (o["rejected_soft"] || []).join(" | "),
          (o["moi"] || []).join(" ")]
  }
  puts "#{bench} round #{r} (+#{extra.size}): #{result}#{secs ? " #{secs}s" : ''}"
  r += 1
  ckpt["next_round"] = r
  unless result == "PASS"
    ckpt.merge!("done" => true, "stop_reason" => "round #{r - 1}: #{result}")
    File.write(ckpt_path + ".tmp", JSON.pretty_generate(ckpt)); File.rename(ckpt_path + ".tmp", ckpt_path)
    break
  end
  File.write(ckpt_path + ".tmp", JSON.pretty_generate(ckpt)); File.rename(ckpt_path + ".tmp", ckpt_path)
end
File.write(ckpt_path + ".tmp", JSON.pretty_generate(ckpt)); File.rename(ckpt_path + ".tmp", ckpt_path)
puts "#{bench}: #{ckpt['stop_reason']}"
