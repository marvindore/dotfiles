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

Surround:

add = "Sa",
replace = "Sr",
delete = "Sd",
find = "Sf",
find_left = "SF",
highlight = "Sh",
update_n_lines = "Sn"


#### Multicursor
<LocalLeader>n : match next
<LocalLeader>N : match prev
<LocalLeader>s : skip next
<LocalLeader>S : skip prev
<up> : select line up
<down> : select line down
<leader><up> : skip line up
<leader><down> : skip line down
<left> : select cursor prev
<right> : select cursor next

### Selections
<leader><left>
<leader><right>
<leader><up>
<leader><down>

> Delete current buffer
:bd

Delete all lines without pattern:
:g!/pattern/d

# Search and Replace

Run command across lines in quickfix
```md
:vimgrep /foo/ **/*.txt
:cdo s/foo/bar/g
```
cdo will target specific words and replace them, it's more granular than cfdo,
which replaces everything in the file.

Overwrite entire files with contents of another file
`:cfdo %delete | 0r /path/to/source.txt | update`
:cfdo — runs the command on each file in the quickfix list.
%delete — deletes all lines in the current buffer.
0r /path/to/source.txt — reads the contents of the source file at line 0 (top of file).
update — saves the file only if it was modified.

Run command across all files in argument list
```md
:args *.txt
:argdo %s/foo/bar/g | update
```

:args sets the list of files.
:argdo runs the substitution in each file.
update saves the file only if it was changed.

