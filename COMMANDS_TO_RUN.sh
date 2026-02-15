#!/bin/bash
# Commands to fix git history on Lobbycheck-Branch
# Run these commands in your local repository directory

# Step 1: Fetch all remote branches to get the latest state
echo "Step 1: Fetching all remote branches..."
git fetch --all

# Step 2: Switch to Lobbycheck-Branch
echo "Step 2: Switching to Lobbycheck-Branch..."
git checkout Lobbycheck-Branch

# Step 3: Reset to the "map and civ updates" commit (removes the squashed commit)
echo "Step 3: Resetting to 22c0c5c (map and civ updates)..."
git reset --hard 22c0c5c

# Step 4: Cherry-pick the "merge" commit from backup/cached branch without committing
echo "Step 4: Cherry-picking changes from backup/cached branch..."
git cherry-pick bc3adb1 --no-commit

# Step 5: Soft reset to unstage the previous commit but keep changes
echo "Step 5: Preparing to combine commits..."
git reset --soft HEAD~1

# Step 6: Create a single combined commit with all changes
echo "Step 6: Creating combined commit..."
git commit -m "Combined update: map/civ data and GUI improvements

This commit combines two separate updates made from different devices:
1. Map and civilization updates - added maps_aoe2.json, updateMaps.py, and moved fields.txt
2. GUI improvements - updated player items, lobby tabs, and check functionality"

# Step 7: Verify the changes
echo "Step 7: Verifying the combined commit..."
git log --oneline -5
echo ""
echo "Files changed in the combined commit:"
git show --stat HEAD

# Step 8: Push to remote (requires confirmation)
echo ""
echo "=========================================="
echo "Ready to push! Review the changes above."
echo "If everything looks correct, run:"
echo ""
echo "  git push origin Lobbycheck-Branch --force-with-lease"
echo ""
echo "=========================================="
