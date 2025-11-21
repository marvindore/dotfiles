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
