#!/usr/bin/env bash
# AI generated (2026-10-23): start or resume the weekend ablation (run_all.sh) detached from the terminal.
# Resuming needs nothing else: every benchmark continues from its own checkpoint.json.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ABLATE_DIR:-$HOME/rbsyn_debug_logs/ablation}"
mkdir -p "$OUT"
INH=()
command -v systemd-inhibit >/dev/null && INH=(systemd-inhibit --what=sleep:idle --who=rbsyn --why=ablation)
cd "$ROOT"
setsid nohup "${INH[@]}" scripts/ablation/run_all.sh >> "$OUT/run_all.out" 2>&1 < /dev/null &
sleep 2
tail -n 3 "$OUT/run_all.status" 2>/dev/null
echo "progress: cat $OUT/run_all.status"
