# GitHub workflow (Lead)

Remote: https://github.com/jared11stevenson-ops/Critter-  (the repo was renamed from `critter-`; the old URL redirects).

- `main` and `master` hold the integrated game (Lead merges agent work, validates, then pushes).
- Agent worktree branches (`worktree-agent*`, `integ`) are pushed as-is.
- `snapshot/<branch>` branches are force-updated every 5 minutes by `tools/autosave.sh` and contain the uncommitted
  state of every worktree. If a container restart loses local work, recover from these.
- The git proxy accepts pushes to `refs/heads/*` only (no custom refs, no remote branch deletes).
- Run autosave: `setsid nohup bash tools/autosave.sh 300 &` (log: /home/user/critter_builds/autosave.log).

## Large files
- Git LFS works end to end through the proxy (tested: 3 MB upload + download). `git lfs` is installed here.
- Plan: after the character artist finishes, track binary assets with LFS going forward
  (`*.glb *.webp *.png *.ogg *.wav *.blend *.psd *.zip` under game/ and tools/), keep Blender/Python scripts as the
  source of truth, and optionally migrate history once no agent has unmerged work (`git lfs migrate import`).
- When cloning on another machine: `git lfs install` before `git clone` (or run `git lfs pull` afterwards).
