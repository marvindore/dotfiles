https://devhints.io/bash

Edit files in loop
git show --name-only HEAD | while read -r f; do [ -f "$f" ] && nvim "$f"; done

sudo lsof -nP -iTCP:5180
kill -9 $(lsof -t -i:5180)
> List Open Files 
> -t stands for terse output > only PIDs
> -i stands for internet, only list network related open files
