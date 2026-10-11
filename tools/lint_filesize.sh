#!/usr/bin/env bash
# File-size lint for v2 GDScript (production rule 7): soft limit 400 lines (warning), hard limit 700 (error).
# Usage: tools/lint_filesize.sh [dir ...]   (default: v2). Exit 1 if any file exceeds the hard limit.
SOFT=${SOFT:-400}
HARD=${HARD:-700}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIRS=("$@")
[ ${#DIRS[@]} -eq 0 ] && DIRS=("$ROOT/v2")
bad=0; warn=0; n=0
while IFS= read -r f; do
  n=$((n+1))
  lines=$(wc -l < "$f")
  if [ "$lines" -gt "$HARD" ]; then
    echo "ERROR  $lines lines (> $HARD): ${f#$ROOT/}"; bad=$((bad+1))
  elif [ "$lines" -gt "$SOFT" ]; then
    echo "warn   $lines lines (> $SOFT): ${f#$ROOT/}"; warn=$((warn+1))
  fi
done < <(find "${DIRS[@]}" -name '*.gd' -not -path '*/.godot/*' -type f | sort)
echo "lint_filesize: $n files, $warn over soft limit ($SOFT), $bad over hard limit ($HARD)"
[ "$bad" -eq 0 ]
