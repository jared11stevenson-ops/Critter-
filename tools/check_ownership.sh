#!/usr/bin/env bash
# Folder-ownership check (production rule 4). Compares the files changed on a branch against the ownership table in
# design/v2/INTERFACES.md (plus the extra rules below) and fails if the branch edits folders its agent does not own.
#
# Usage: tools/check_ownership.sh [--agent NAME] [--base REF] [--list]
#   --agent  lead|platform|combat|character|arena|ui|qa  (default: inferred from branch name worktree-v2-<x>;
#            unknown branches such as master/main/integ are skipped)
#   --base   ref to diff against (default origin/master, else master)
#   --list   print the resolved rules and exit
# The longest matching prefix decides a file's owners. Rules come from the INTERFACES.md table (lines starting with v2/)
# and from EXTRA below (Lead-approved refinements: tools split, shared tests, platform-owned CI/lint files).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2
AGENT=""; BASE=""; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$(echo "$2" | tr 'A-Z' 'a-z')"; shift 2;;
    --base) BASE="$2"; shift 2;;
    --list) LIST=1; shift;;
    *) echo "unknown argument $1" >&2; exit 2;;
  esac
done

# prefix<TAB>owners (comma separated; 'any' = shared)
EXTRA=$'v2/tools/\tplatform,qa\nv2/tools/sim/\tcombat\nv2/tools/qa/tests/\tany\nv2/data/story/\tplatform
.github/\tplatform\ntools/check_ownership.sh\tplatform\ntools/lint_filesize.sh\tplatform\ndesign/\tlead\nproduction/\tlead
v2/src/boot/\tlead\nv2/project.godot\tlead\nv2/icon.svg\tlead\nv2/icon.svg.import\tlead\nv2/data/\tcombat,lead'

normalize_owner() {  # first word of the table's owner column -> agent id
  local w; w="$(echo "$1" | tr 'A-Z' 'a-z' | sed -E 's#[/ ].*##')"
  case "$w" in lead) echo lead;; platform) echo platform;; combat) echo combat;; character) echo character;;
    arena) echo arena;; ui) echo ui;; qa) echo qa;; *) echo "$w";; esac
}

RULES=""
while IFS= read -r line; do
  path="$(echo "$line" | awk '{print $1}')"
  rest="$(echo "$line" | sed -E 's/^[^ ]+ +//')"
  prefix="${path%%\**}"          # cut at the first wildcard
  prefix="${prefix%/}/"; [ "$path" = "v2/project.godot" ] && prefix="v2/project.godot"
  RULES+="$prefix"$'\t'"$(normalize_owner "$rest")"$'\n'
done < <(grep -E '^v2/' design/v2/INTERFACES.md | grep -vE '^v2/data/critters.*Combat Engineer owns' | sed -E 's/  +/ /')
RULES+="v2/data/critters/"$'\t'"combat,lead"$'\n'"v2/data/moves/"$'\t'"combat,lead"$'\n'
RULES+="$EXTRA"$'\n'

if [ "$LIST" -eq 1 ]; then printf '%s\n' "$RULES" | grep -v '^$'; exit 0; fi

BR="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
if [ -z "$AGENT" ]; then
  case "$BR" in
    worktree-v2-art|worktree-v2-character) AGENT=character;;
    worktree-v2-*) AGENT="${BR#worktree-v2-}";;
    *) echo "check_ownership: branch '$BR' is not an agent branch; skipped"; exit 0;;
  esac
fi
[ "$AGENT" = lead ] && { echo "check_ownership: lead may edit any folder"; exit 0; }
if [ -z "$BASE" ]; then
  for c in origin/master master; do git rev-parse --verify -q "$c" >/dev/null && BASE="$c" && break; done
fi
MB="$(git merge-base "$BASE" HEAD 2>/dev/null || echo "$BASE")"
FILES="$(git diff --name-only "$MB" HEAD; git diff --name-only; git ls-files --others --exclude-standard)"
FILES="$(printf '%s\n' "$FILES" | sort -u | grep -v '^$')"
[ -z "$FILES" ] && { echo "check_ownership: no changed files vs $BASE (agent $AGENT)"; exit 0; }

viol=0
while IFS= read -r f; do
  best=""; bestlen=-1
  while IFS=$'\t' read -r prefix owners; do
    [ -z "$prefix" ] && continue
    case "$f" in "$prefix"*) [ ${#prefix} -ge "$bestlen" ] && { best="$owners"; bestlen=${#prefix}; };; esac
  done <<< "$RULES"
  [ -z "$best" ] && best="lead"          # anything unlisted (v1 game/, root files) belongs to the Lead
  case ",$best," in *",any,"*|*",$AGENT,"*) ;; *)
    echo "VIOLATION: $f is owned by [$best], not '$AGENT'"; viol=$((viol+1));; esac
done <<< "$FILES"
echo "check_ownership: agent=$AGENT base=$BASE, $(printf '%s\n' "$FILES" | wc -l) changed files, $viol violation(s)"
[ "$viol" -eq 0 ]
