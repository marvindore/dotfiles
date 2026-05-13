https://devhints.io/bash

Edit files in loop
git show --name-only HEAD | while read -r f; do [ -f "$f" ] && nvim "$f"; done

# kill everything listening on tcp:<number>
kill -9 $(lsof -ti tcp:4200)
> List Open Files 
> -t stands for terse output > only PIDs
> -i stands for internet, only list network related open files
