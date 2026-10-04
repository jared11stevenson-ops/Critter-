# RESUME — how to pick production back up (container restart / usage limit / new session)

1. Project: `/home/user/critter` (master = Lead). Agent worktrees: `.claude/worktrees/agent-a8084abf368f86900`
   (Agent 1, branch worktree-agent-a8084abf368f86900) and `.claude/worktrees/agent-a1fe24b4478926803`
   (Agent 2, branch worktree-agent-a1fe24b4478926803). Integration worktree: `/home/user/critter_integ` (branch integ).
2. Snapshot any uncommitted agent work first:
   `for d in .claude/worktrees/agent-*/; do git -C $d add -A && git -C $d commit -qm "WIP snapshot"; done`
   Autosave snapshots also live in `refs/snapshots/<branch>` (`git for-each-ref refs/snapshots`).
3. Restart the autosave failsafe: `nohup tools/autosave.sh 600 >/dev/null 2>&1 &` (log: /home/user/critter_builds/autosave.log).
4. Engines: /opt/godot/Godot_v4.7.2-stable_linux.x86_64 and _v4.3 (re-download from GitHub releases if missing).
   Python deps: `pip install pillow numpy scipy soundfile rembg onnxruntime`.
5. Relaunch agents with "resume" briefs: work only in their worktree, read CONTRACTS/GDD/AGENTn_NOTES, continue remaining deliverables,
   commit every ~20 min, validate on both engines.
6. Integrate: in /home/user/critter_integ: `git reset --hard && git clean -fd -e .godot`, merge master + both agent branches,
   import (`godot --headless --editor --quit`), run `tools/validate.sh`, then `tools/shot.sh` QA scripts in tools/qa/scripts/.
7. Backups to user: `tools/package.sh /home/user/critter_builds` → send zip.
8. GitHub: remote `origin` = jared11stevenson-ops/critter- (push needs the Claude GitHub App installed with write access).
Pending from user: Youngyumeprophecy music files (6 slots: title, hub, explore_reaches, combat, boss, ending).

## Creator feedback on v0.8.0 (Oct 4)
- Low graphics preset fixed the lag (keep Auto→Medium default, Low as fallback).
- 3D Aruun is "a good start": keep making him match his reference art and the hi-res reference pack
  (design/model_sheets/aruun/): hunched posture, hook horns, beetle-mask head, chitin plates, ragged cloak, not pale.
- Everything else fine for now. **Tomorrow: complete overhaul of all graphics** (world, characters, creatures, VFX).
- Status: no agents running; all work committed on master (v0.8.0) + agent branches; autosave script running.
