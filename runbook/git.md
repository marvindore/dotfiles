Cherry pick a range of commits
> This will cherry-pick 4 commits, head + 3
git cherry-pick origin/feature-branch~3..origin/feature-branch

View contents of file at commit:
git show <hash>:<file> | grep -A 14 "phrase" 

**cherry pick without merges**
`git cherry-pick -S $(git rev-list --reverse --no-merges 2e67e64c^..d4c233be)`

```md
    # list file names in commit
    git diff-tree --no-commit-id --name-only -r <commitHash>

    # search for commits with the word "keyword" in the commit message
    git log --grep="keyword"

    # Search for commits with either "fix" or "ai" in the commit message
    git log --grep="fix" --grep="ai"

    # Search for commits with both "fix" and "ai" in the commit message (AND logic)
    git log --grep="fix" | grep "ai"

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

    # Who deleted the file in a mod/del conflict
    git log --diff-filter=D --summary -- <file_name>
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

## Forked OpenSource Repos
    # Clone your fork (this will be your base directory)
    mkdir <REPO_NAME>
    cd <REPO_NAME>
    git clone --bare https://github.com/<YOUR_USERNAME>/<REPO_NAME>.git .git
    
    # Tell Git to map remote branches to local tracking branches
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    # Fetch from your fork to update the hidden references
    git fetch origin

    # Add the original repository as an upstream remote
    git remote add upstream <REPO_NAME.git>

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


1. Does main have file changes that develop does not have?

git fetch origin
git diff --stat $(git merge-base origin/main origin/develop) origin/main

This shows what main changed since the branches split. No output means main has no code of its own. Today it prints nothing.

2. Will the release merge put anything on main that is not in develop?

git diff --stat $(git merge-tree --write-tree origin/main origin/develop) origin/develop

This builds the merge result without changing any branch and compares it with develop. No output means that after the merge, main will be exactly develop. Today it prints nothing.

Do not use this for the check

git diff main develop

This compares the two branches directly. It shows develop's 20 new commits, but it does not tell you which side made each change. Old lines that develop has since changed look the same as new lines on main.

After the release and the fast-forward

When you have done the release merge and the fast-forward, both commit counts will be zero:

git rev-list --left-right --count origin/main...origin/develop
0    0




----
Step 1: merge develop into main (GitHub UI, "Create a merge commit")

            o---o---o ... o---M        ← main
           /                 /
 ---- base                  /
           \               /
            x---x---x ... x            ← develop

M has two parents: the last commit of main and the last commit of develop. So main now contains all of develop. develop has no commit that main does not have.

develop is the default branch, so GitHub does not offer to delete it. If it does, do not delete it.

Step 2: fast-forward develop to M

develop is now fully inside main. So git can move the develop pointer forward to M. It does not make a new commit:

git fetch origin
git switch develop
git merge --ff-only origin/main
git push origin develop

            o---o---o ... o---M        ← main, develop
           /                 /
 ---- base                  /
           \               /
            x---x---x ... x

Both branches point to the same commit. The count is now:

git rev-list --left-right --count origin/main...origin/develop
0    0

Next release

Developers merge feature PRs into develop as usual:

 ... M---f1---f2---f3        ← develop
     ↑
    main

main is fully inside develop, so the history stays a straight line. The next release merge is clean, and after the next fast-forward the count goes back to 0 0.

If develop is protected and needs a PR

The GitHub UI cannot fast-forward a branch. If you merge a main → develop PR with "Create a merge commit", you get this:

 ... o---M                   ← main
          \
 ... x-----B                 ← develop  (B = back-merge commit)

develop has one extra commit, B, that main does not have. This is acceptable. B contains no code, and it goes to main with the next release. The bad case is the other direction, where main has commits that develop does not have. That is why you have 89 commits now: releases went into main, and main never went back into develop.

To avoid B, get one of these:

- Permission to push a fast-forward to develop (a bypass in the branch rules), so you can do Step 2.
- A small GitHub Action that runs git merge --ff-only origin/main and pushes to develop after each push to main.

A merge commit is not just an extra commit, it points back to both branches, so
the branch that gets the merge commit now contains all the commits of both
branches (like a pointer).



Which branches contains XYZ commit?
git branch --contains XYZ

What commit deleted my files ABC?
git log --diff-filter=D --all -- ABC
list all commit history
git log --all -- ABC

See what author changed
git show --summary <commit_hash>

visualize graph of file history:
git log --graph --decorate --oneline --all -- ABC

git sign multi  commits:
git rebase HEAD~100 --exec 'git commit --amend --no-edit -S'

resigning many commits but you want to preserve the merges so the rebase doesn't
replay the merge commits use:
git rebase -i HEAD~3 --rebase-merges -S
