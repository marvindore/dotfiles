### diff compare two files
```bash
# from cli
nvim -d file1 file2

# from nvim copying & pasting text
:vnew
-- paste your contents
:windo diffthis
:windo diffoff

:vert diffsplit filename 
```

-- echo v:lua.vim.uv.os_name().sysname -- lua print(vim.uv.os_uname().sysname)
-- Go to previous location Ctrl + o
-- Go to next location Ctrl + 
-- Go to next method, change, diagnostic [] m|c|d
-- Increment Decrement number Ctrl-A Ctrl-X
-- substitue in block <,>s/old/new/g
-- jump to matching brace %

-- {Marks}
-- create mark m<register>
-- go to mark '<register>
-- :delmarks! will delete all lowercase marks
-- lowercase marks relate to file, uppercase marks are global

-- buffer of messages
-- :redir > messages.txt
-- :messages
-- :redir END
-- :e messages.txt

