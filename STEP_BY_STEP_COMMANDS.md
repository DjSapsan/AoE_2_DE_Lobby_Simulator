# Step-by-Step Commands to Fix Git History

Copy and paste these commands one at a time into your terminal.

## Prerequisites
Make sure you're in your local repository directory:
```bash
cd /path/to/AoE_2_DE_Lobby_Simulator
```

## Step 1: Fetch all remote branches
```bash
git fetch --all
```

## Step 2: Switch to Lobbycheck-Branch
```bash
git checkout Lobbycheck-Branch
```

## Step 3: Reset to the "map and civ updates" commit
This removes the squashed commit that was missing the map/civ data:
```bash
git reset --hard 22c0c5c
```

## Step 4: Cherry-pick changes from backup/cached branch
This brings in the GUI improvements without committing yet:
```bash
git cherry-pick bc3adb1 --no-commit
```

## Step 5: Soft reset to prepare for combining
This unstages the previous "map and civ updates" commit but keeps all changes:
```bash
git reset --soft HEAD~1
```

## Step 6: Create the combined commit
This creates a single commit with both the map/civ data AND GUI improvements:
```bash
git commit -m "Combined update: map/civ data and GUI improvements

This commit combines two separate updates made from different devices:
1. Map and civilization updates - added maps_aoe2.json, updateMaps.py, and moved fields.txt
2. GUI improvements - updated player items, lobby tabs, and check functionality"
```

## Step 7: Verify the changes
Check that the commit looks correct:
```bash
git log --oneline -5
```

You should see:
```
<new-hash> (HEAD -> Lobbycheck-Branch) Combined update: map/civ data and GUI improvements
94c6f8c GUI work 2
00ac7e7 GUI work
cf24dfa GUI improvement and moving towards implementing lobbycheck
a6de2ae improving gui
```

View the files changed:
```bash
git show --stat HEAD
```

You should see 16 files changed with 2168 insertions and 332 deletions.

## Step 8: Push to remote
⚠️ **IMPORTANT**: This rewrites history, so use `--force-with-lease` for safety:
```bash
git push origin Lobbycheck-Branch --force-with-lease
```

The `--force-with-lease` flag will fail if someone else has pushed to the branch, protecting you from overwriting their work.

## Optional: Clean up backup/cached branch
After verifying everything is correct, you can delete the backup/cached branch:
```bash
git push origin --delete backup/cached
git branch -d backup/cached
```

## Troubleshooting

### If git cherry-pick fails with conflicts
This shouldn't happen, but if it does:
1. Resolve the conflicts manually
2. Run `git add .` to stage the resolved files
3. Continue with Step 5

### If --force-with-lease fails
This means someone has pushed to Lobbycheck-Branch since you fetched. In that case:
1. Don't use `--force` - it could overwrite their changes
2. Run `git fetch origin Lobbycheck-Branch` to see what changed
3. Contact me if you need help merging the new changes

### Creating a backup before pushing
If you want to be extra safe:
```bash
git branch Lobbycheck-Branch-old-backup
```

This creates a local backup you can restore if needed:
```bash
git checkout Lobbycheck-Branch-old-backup  # to restore
```
