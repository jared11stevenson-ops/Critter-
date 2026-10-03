#!/usr/bin/env bash
# Failsafe: every INTERVAL seconds, snapshot every worktree (incl. uncommitted + untracked files)
# into refs/snapshots/<branch> WITHOUT touching the agents' branches, index or files,
# then try to push all branches + snapshots to GitHub (silently skipped while push access is missing).
INTERVAL=${1:-600}
REPO=/home/user/critter
LOG=/home/user/critter_builds/autosave.log
mkdir -p /home/user/critter_builds
while true; do
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  git -C $REPO worktree list --porcelain | awk '/^worktree /{print $2}' | while read wt; do
    br=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null) || continue
    tmpidx=$(mktemp)
    gitdir=$(git -C "$wt" rev-parse --git-dir)
    cp "$gitdir/index" "$tmpidx" 2>/dev/null
    GIT_INDEX_FILE=$tmpidx git -C "$wt" add -A 2>/dev/null
    tree=$(GIT_INDEX_FILE=$tmpidx git -C "$wt" write-tree 2>/dev/null)
    rm -f "$tmpidx"
    [ -z "$tree" ] && continue
    head=$(git -C "$wt" rev-parse HEAD)
    if [ "$tree" != "$(git -C "$wt" rev-parse HEAD^{tree})" ]; then
      c=$(echo "autosave $ts ($br)" | git -C "$wt" -c user.name=autosave -c user.email=autosave@critter.local commit-tree "$tree" -p "$head")
      git -C $REPO update-ref "refs/snapshots/$br" "$c"
      echo "$ts snapshot $br -> ${c:0:8}" >> $LOG
    fi
  done
  if git -C $REPO push -q origin 'refs/heads/*:refs/heads/*' 'refs/snapshots/*:refs/snapshots/*' >/dev/null 2>&1; then
    echo "$ts pushed to GitHub" >> $LOG
  fi
  sleep $INTERVAL
done
