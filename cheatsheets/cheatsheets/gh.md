gh create pr --base main --title "Hello world" --body "
Line1
Line2
"
echo -e "line1\nline2\nline3\n"  | gh create pr --body-file -
