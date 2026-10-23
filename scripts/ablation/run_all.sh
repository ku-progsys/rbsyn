#!/usr/bin/env bash
# AI generated (2026-10-23): unattended weekend driver. Runs ablate.rb for each benchmark below, one at a time
# (pool build, then rounds until the first non-PASS). A benchmark that fails (pool or rounds) is logged and the
# next one starts. Rerunning resumes: finished benchmarks are skipped by ablate.rb, unfinished ones continue from
# their checkpoint (the interrupted round is rerun). Start and resume are the same command; nothing to specify.
#
# start / resume (detached, survives closing the terminal, keeps the machine awake):
#   scripts/ablation/start.sh
# progress:  cat ~/rbsyn_debug_logs/ablation/run_all.status
# stop:      kill $(cat ~/rbsyn_debug_logs/ablation/run_all.pid)   (then the running test, see ablation_handoff.md)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
OUT="${ABLATE_DIR:-$HOME/rbsyn_debug_logs/ablation}"
mkdir -p "$OUT"
# only one driver at a time; a stale pid file (after a reboot or kill) is ignored
if [ -f "$OUT/run_all.pid" ] && kill -0 "$(cat "$OUT/run_all.pid")" 2>/dev/null; then
  echo "already running (pid $(cat "$OUT/run_all.pid"))"; exit 1
fi
echo $$ > "$OUT/run_all.pid"
STATUS="$OUT/run_all.status"
LIMIT="${LIMIT:-1200}"
SEED="${SEED:-1}"

# order: the three from the handoff first, then the other fast passing benchmarks
BENCHES=(
  gitlab/issue_close
  diaspora/invitation_code_use
  synthetic/user_exists
  discourse/clear_global_notice_if_needed
  gitlab/issue_reopen
  diaspora/user_process_invite_acceptence
  synthetic/method_chain
  synthetic/branch
  synthetic/lvar
  synthetic/false
)

log() { echo "$(date '+%F %T') $*" | tee -a "$STATUS"; }

log "start: ${#BENCHES[@]} benchmarks, limit ${LIMIT}s, seed $SEED, commit $(git rev-parse --short HEAD)"
for b in "${BENCHES[@]}"; do
  d="$OUT/${b//\//_}"
  log "$b: begin"
  ruby scripts/ablation/ablate.rb "$b" "$LIMIT" "$SEED" >> "$OUT/run_all.out" 2>&1
  rc=$?
  last="$(tail -n 1 "$d/${b//\//_}.csv" 2>/dev/null | cut -c1-200)"
  stop="$(ruby -rjson -e 'c = JSON.parse(File.read(ARGV[0])); puts c["stop_reason"] || "next_round #{c["next_round"]}"' "$d/checkpoint.json" 2>/dev/null || echo "no checkpoint (pool build failed?)")"
  log "$b: exit $rc, $stop | last row: $last"
done
log "all done"
rm -f "$OUT/run_all.pid"
