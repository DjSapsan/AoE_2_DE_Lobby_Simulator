# Quick Command Reference

## Copy-Paste All Commands (run in sequence)

```bash
# Navigate to your repository
cd /path/to/AoE_2_DE_Lobby_Simulator

# Fetch latest from remote
git fetch --all

# Switch to Lobbycheck-Branch
git checkout Lobbycheck-Branch

# Reset to map and civ updates commit
git reset --hard 22c0c5c

# Cherry-pick GUI changes without committing
git cherry-pick bc3adb1 --no-commit

# Unstage previous commit but keep all changes
git reset --soft HEAD~1

# Create combined commit
git commit -m "Combined update: map/civ data and GUI improvements

This commit combines two separate updates made from different devices:
1. Map and civilization updates - added maps_aoe2.json, updateMaps.py, and moved fields.txt
2. GUI improvements - updated player items, lobby tabs, and check functionality"

# Verify changes
git log --oneline -5
git show --stat HEAD

# Push to remote (review changes first!)
git push origin Lobbycheck-Branch --force-with-lease
```

## What This Does

1. **Fetches** all remote branches
2. **Switches** to Lobbycheck-Branch
3. **Resets** to commit 22c0c5c (removes squashed commit)
4. **Cherry-picks** commit bc3adb1 (adds GUI changes)
5. **Combines** both into a single commit
6. **Pushes** the fixed history to remote

## Result

✅ Single commit with ALL changes from both devices:
- 16 files changed
- 2,168 insertions(+)
- 332 deletions(-)
- Nothing lost!

## Safety Notes

- `--force-with-lease` is safer than `--force`
- It will fail if someone else pushed to the branch
- Create a backup branch first if you're unsure:
  ```bash
  git branch Lobbycheck-Branch-backup
  ```
