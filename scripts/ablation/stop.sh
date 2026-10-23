#!/usr/bin/env bash
# AI generated (2026-10-23): stop the weekend ablation (driver, runner, and the running benchmark test).
# Resume later with scripts/ablation/start.sh; the interrupted round is rerun from its checkpoint.
OUT="${ABLATE_DIR:-$HOME/rbsyn_debug_logs/ablation}"
[ -f "$OUT/run_all.pid" ] && kill "$(cat "$OUT/run_all.pid")" 2>/dev/null
# patterns anchored on the processes' own command lines, so this script's shell never matches
ps -eo pid,args | awk '$2 ~ /systemd-inhibit$/ && /--who=rbsyn/ {print $1}' | xargs -r kill 2>/dev/null
ps -eo pid,args | awk '$2 == "ruby" && $3 == "scripts/ablation/ablate.rb" {print $1}' | xargs -r kill 2>/dev/null
sleep 1
ps -eo pid,args | awk '/bin\/ruby .*rake_test_loader\.rb test\/benchmark\// && !/awk/ {print $1}' | xargs -r kill -9 2>/dev/null
rm -f "$OUT/run_all.pid"
sleep 1
left="$(ps -eo pid,args | grep -E 'run_all\.sh|scripts/ablation/ablate\.rb|rake_test_loader\.rb test/benchmark/' | grep -v grep)"
if [ -n "$left" ]; then echo "still running:"; echo "$left"; else echo "stopped"; fi
echo "$(date '+%F %T') stopped by stop.sh" >> "$OUT/run_all.status"
