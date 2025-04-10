### diff compare two files
```bash
# from cli
nvim -d file1 file2

# from nvim copying & pasting text
:vnew
-- paste your contents
:windo diffthis
:windo diffoff
:set diffopt+=iwhite

:vert diffsplit filename 
```
### Marks
```
Create local marks
m<lowercase_letter> 

Create global marks
m<uppercase_letter>

jump to mark (single quote)
'<letter>

jump to exact location of mark (backtick)
`<letter>
```
** close buffer without exiting vim**
`:bd`

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

> For various plugin pickers to work correctly, you need to replace vim.ui.select with your desired picker (as the default vim.ui.select is very basic). Here are some examples:
fzf-lua - call require('fzf-lua').register_ui_select()
telescope - setup telescope-ui-select.nvim plugin
snacks.picker - enable ui_select config
mini.pick - set vim.ui.select = require('mini.pick').ui_select
