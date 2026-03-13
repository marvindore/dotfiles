gh create pr --base main --title "Hello world" --body "
Line1
Line2
"
echo -e "line1\nline2\nline3\n"  | gh create pr --body-file -

```

# assuming you're on a feature branch already pushed with: git push -u origin HEAD
gh pr create --base main --fill

gh pr create --base main \
  --title "$(git log -1 --pretty=%s)" \
  --body  "$(git log -1 --pretty=%b)"

gh pr create --base main --fill --draft

gh pr create --base main --fill --web
```
