Cherry pick a range of commits
> This will cherry-pick 4 commits, head + 3
git cherry-pick origin/feature-branch~3..origin/feature-branch

```md
    # list file names in commit
    git diff-tree --no-commit-id --name-only -r <commitHash>

    # search for commits with the word "keyword" in the commit message
    git log --grep="keyword"

    # Search for commits with either "payroll" or "ai" in the commit message
    git log --grep="payroll" --grep="ai"

    # Search for commits with both "payroll" and "ai" in the commit message (AND logic)
    git log --grep="payroll" | grep "ai"

    # Search for commits by a specific author
    git log --author="Marvin"

    # Search for commits within a specific date range
    git log --since="2025-01-01" --until="2025-08-01"

    # Show commits that affected a specific file
    git log -- path/to/file

    # Search for commits starting with a specific hash prefix
    git log --abbrev-commit --pretty=oneline | grep "^abc123"

    # Customize the output format of git log
    git log --pretty=format:"%h - %an, %ar : %s"

    # Show the diff for each commit
    git log -p

    # Limit the log to a specific branch
    git log branch-name
    # Show full details of a specific commit
    git show <commit-hash>

    # Show only the names of files changed in a specific commit
    git show <commit-hash> --name-only
    # Show a summary of changes (lines added/removed) in a specific commit
    git show <commit-hash> --stat

    # Show the content of a specific file at a specific commit
    git show <commit-hash>:path/to/file

    # Show commits after the common anestor
    git log --graph --oneline --decorate --ancestry-path BASE..branch1

    # Show commits from BASE and before
    git log --graph --decorate <hash>
```

diff
Use A B (two dots) when you want a direct comparison.
Use A...B (three dots) when you want to see what B adds relative to the shared history with A
git diff -w // ignore whitespace
git diff --ignore-space-at-eol

## Worktree
```
// Missing remote refs
git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git config --add remote.origin.fetch "+refs/tags/*:refs/tags/*"   # optional
git fetch --all --prune
```

### Bare Repo
ref: [blog](https://nicknisi.com/posts/git-worktrees/)
```
mkdir project && cd project
git clone --bare git@github.com:user/project.git .bare
echo "gitdir: ./.bare" > .git
```

## Forked Repos
    # Clone your fork (this will be your base directory)
    mkdir <REPO_NAME>
    cd <REPO_NAME>
    git clone --bare https://github.com/<YOUR_USERNAME>/<REPO_NAME>.git .git
    
    # Tell Git to map remote branches to local tracking branches
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    # Fetch from your fork to update the hidden references
    git fetch origin

    # Add the original repository as an upstream remote
    git remote add upstream git@github.com:<ORIGINAL_OWNER>//<REPO_NAME>.git

    # Set the fetch mapping for the upstream remote too
    git config remote.upstream.fetch "+refs/heads/*:refs/remotes/upstream/*"
    
    # Run this from ANY worktree or your base repository
    git fetch upstream

    # To update your local main branch (run this from your base directory)
    git worktree add feature-xyz upstream/main
    git rebase upstream/<MAIN_BRANCH>
    git push origin feature-xyz

    # Run from inside the worktree directory: ../<REPO_NAME>-<FEATURE_BRANCH_NAME>
    gh pr create \
      --repo <ORIGINAL_OWNER>/<REPO_NAME> \
      --base <MAIN_BRANCH> \
      --head <YOUR_USERNAME>:<FEATURE_BRANCH_NAME> \
      --title "Brief description of the PR" \
      --body "Detailed explanation of what this PR does, fixes, or adds."

    # First, navigate out of the worktree directory you want to delete
    # (e.g., go back to your base repository)
    cd ../<REPO_NAME>

    # Remove the worktree directory
    git worktree remove ../<REPO_NAME>-<FEATURE_BRANCH_NAME>

    # Delete the local branch reference
    git branch -d <FEATURE_BRANCH_NAME>

    # Delete the remote feature branch from your GitHub fork
    git push origin --delete <FEATURE_BRANCH_NAME>
