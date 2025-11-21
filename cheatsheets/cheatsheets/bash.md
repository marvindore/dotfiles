https://devhints.io/bash

Edit files in loop
git show --name-only HEAD | while read -r f; do [ -f "$f" ] && nvim "$f"; done
