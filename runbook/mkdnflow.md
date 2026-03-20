# Mkdnflow Cheatsheet

## Navigation
| Key          | Mode | Action                         |
|--------------|------|--------------------------------|
| `<CR>`       | n, v | Follow/create link, fold heading |
| `<BS>`       | n    | Go back (previous buffer)      |
| `<Del>`      | n    | Go forward                     |
| `<Tab>`      | n    | Jump to next link              |
| `<S-Tab>`    | n    | Jump to previous link          |
| `]]`         | n    | Next heading                   |
| `[[`         | n    | Previous heading               |
| `][`         | n    | Next heading (same level)      |
| `[]`         | n    | Previous heading (same level)  |

## Links
| Key              | Mode | Action                          |
|------------------|------|---------------------------------|
| `<CR>`           | n    | Create link from word under cursor |
| `<leader>p`      | n, v | Create link from clipboard URL  |
| `<M-CR>`         | n    | Destroy link (keep text)        |
| `<M-CR>`         | v    | Tag span with ID                |
| `<F2>`           | n    | Rename/move link source file    |
| `<leader>mya`    | n    | Yank anchor link to heading     |
| `<leader>myf`    | n    | Yank file + anchor link         |

## Headings
| Key   | Mode | Action                  |
|-------|------|-------------------------|
| `+`   | n, v | Increase heading level  |

## To-Do Lists
| Key          | Mode | Action                  |
|--------------|------|-------------------------|
| `<C-Space>`  | n, v | Toggle to-do status     |

Write `- [ ] task` then `<C-Space>` cycles: `[ ]` -> `[-]` -> `[x]` -> `[ ]`

## Lists
| Key           | Mode | Action                  |
|---------------|------|-------------------------|
| `<leader>nn`  | n    | Update list numbering   |
| `<C-t>`       | i    | Indent list item        |
| `<C-d>`       | i    | Dedent list item        |

## Tables
| Key           | Mode | Action                      |
|---------------|------|-----------------------------|
| `<Tab>`       | i    | Next cell (in table only)   |
| `<S-Tab>`     | i    | Previous cell (in table only)|
| `<M-CR>`      | i    | Previous row                |
| `<leader>ir`  | n    | Insert row below            |
| `<leader>iR`  | n    | Insert row above            |
| `<leader>ic`  | n    | Insert column after         |
| `<leader>iC`  | n    | Insert column before        |

Create table: `:MkdnTable 3 4` (3 cols, 4 rows)
Format table: `:MkdnTableFormat`

## Commands
| Command              | Action                         |
|----------------------|--------------------------------|
| `:NotesPlus`          | Open ~/notesplus/index.md          |
| `:MkdnTable 3 4`    | Create 3x4 table               |
| `:MkdnTableFormat`   | Format table under cursor      |
| `:MkdnBacklinks`     | Show files linking to this one |
| `:MkdnDeadLinks`     | Find broken links              |
| `:MkdnSortToDoList`  | Sort to-dos by status          |
| `:MkdnCleanConfig`   | Show optimized config          |

## Workflow
1. `:NotesPlus` to open index
2. Type a task name, `<CR>` to create linked note
3. `<BS>` to go back, `<Del>` to go forward
4. `<C-Space>` to toggle checkboxes
5. `<leader>?` to see all buffer-local keymaps
