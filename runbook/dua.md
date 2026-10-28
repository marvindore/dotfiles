# dua — macOS disk cleanup

Tested with dua 2.45.0. Keys come from `dua config show-default`.

## Prerequisites

- Give the terminal Full Disk Access: *System Settings → Privacy & Security → Full Disk Access*. If you do not, dua skips most of `~/Library` and reports sizes that are too small.
- `Ctrl+t` moves to the Trash. Space is not freed until you empty the Trash.
- `Ctrl+r` deletes permanently. You cannot undo it.

## Procedure: disk is full

1. Find what uses the space:
   ```sh
   dua ~                          # flat list, largest at the bottom
   dua a -d 2 ~                   # tree, 2 levels deep
   sudo dua i -x /System/Volumes/Data   # full data volume, slower
   ```
2. Remove build output (bin/obj, node_modules, target):
   ```sh
   dua clean ~/work
   ```
   Mark the folders, then press `Ctrl+t`.
3. Clean the caches with each tool's own command:
   ```sh
   brew cleanup --prune=all
   docker system prune -a
   dotnet nuget locals all --clear
   ```
4. Look through the rest interactively:
   ```sh
   dua i ~
   ```
   Open folders with `l`, press `Space` to mark, `Tab` to review the marks, then `Ctrl+t`.
5. Empty the Trash.
6. If dua shows less used space than macOS reports, check for Time Machine local snapshots:
   ```sh
   tmutil listlocalsnapshots /
   ```

## Common space users

| Path | Action |
|---|---|
| `~/Library/Caches` | Safe to delete. Apps rebuild these files. |
| `~/.nuget/packages` | `dotnet nuget locals all --clear` |
| `~/Library/Developer/Xcode/DerivedData` | Safe to delete. |
| `~/.npm`, `~/.gradle`, `~/.m2` | Safe to delete. Packages download again when needed. |
| `~/Library/Containers/com.docker.docker` | **Do not delete with dua.** Use `docker system prune -a`. |
| `~/Downloads`, `~/.Trash` | Check by hand. |

## Monthly routine

1. `dua clean ~/work` → mark the folders → `Ctrl+t`
2. `dua i ~` → open `Library/Caches` → delete the large entries
3. `brew cleanup --prune=all && docker system prune -a`
4. Empty the Trash.

## Track growth

```sh
dua i --export ~/dua-$(date +%F).snap ~
# Some weeks later:
dua i --export ~/dua-new.snap ~
dua diff ~/dua-OLD.snap ~/dua-new.snap --directories-only -d 3
```

## Commands

| Command | Action |
|---|---|
| `dua ~` | List sizes once |
| `dua a -d 2 ~` | Size tree, 2 levels |
| `dua i ~` | Interactive interface |
| `dua clean ~/work` | Find folders that are safe to throw away |
| `dua i -x /` | Do not cross into other filesystems |
| `dua i -i /abs/path ~` | Skip a folder (absolute path) |
| `dua flamegraph ~` | SVG flame graph |
| `dua diff OLD NEW` | Compare two snapshots |
| `dua config edit` | Edit settings and keybindings |

## Keys (`dua i`)

| Key | Action |
|---|---|
| `j`/`k`, `↓`/`↑` | Move down / up |
| `l`/`o`/`Enter`/`→` | Open a folder |
| `h`/`u`/`Backspace`/`←` | Go to the parent folder |
| `U` | Scan the parent folder |
| `H`/`G` | Top / bottom |
| `Ctrl+d`/`Ctrl+u` | Page down / up |
| `s` `m` `c` `n` | Sort by size / mtime / count / name |
| `/` | Search |
| `O` | Open in Finder or the default app |
| `Space` | Mark or unmark |
| `d` | Mark or unmark, then move down |
| `x` | Mark for deletion |
| `a` | Mark or unmark all |
| `t` / `X` | Show cleanup candidates / mark all of them |
| `i` / `I` | Show Git-ignored entries / mark all of them |
| `Tab` | Go to the marked-items pane |
| `Ctrl+t` | Move marked items to the Trash |
| `Ctrl+r` | **Delete marked items permanently** |
| `r` / `R` | Rescan selected / rescan all |
| `?` | Help |
| `q` / `Esc` | Quit / go back |
