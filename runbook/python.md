## Environment variable precedence in pydantic-settings (and why .env files lose)

`pydantic-settings` intentionally gives real environment variables priority over `.env` files:

```
actual env vars (shell, ~/.workrc, CI secrets)  >  .env file
```

This is correct for production (K8s injects real env vars; no .env file exists), but it creates friction locally when you have global credentials in `~/.workrc` and a project that needs different ones.

**The fix: inject project .env into the shell before the process runs**, so the project values sit at the same level as globals and win by order of loading.

Option A — mise (preferred if project already uses mise):
```toml
# in the project's mise.toml
[env]
_.file = ".env"
```
When you `cd` into the project, mise loads `.env` into your shell. Project credentials override globals automatically.

Option B — direnv:
```bash
# create .envrc in project root
dotenv .env
```
`direnv allow` once, then it auto-loads/unloads on `cd`.

Both achieve the same thing. Use whichever the project already has tooling for. See mise.md for the mise approach.

---

## Pyrefly go-to-definition does not follow imports

When Neovim `gd` does not jump from a Python import to the real file, first assume the language server cannot resolve the import. Neovim is only sending an LSP definition request; Pyrefly decides where the symbol lives.

Check what Pyrefly thinks the project root and import roots are:

```bash
~/.local/share/nvim/mason/bin/pyrefly dump-config path/to/current_file.py
```

Look for the `Resolving imports from:` section.

Common problem with `src` layout:

```text
project/
  pyproject.toml
  src/
    agent/
      instruction.py
```

If Pyrefly reports this:

```text
Import root (inferred from project layout): ".../project/src"
```

then imports should normally omit `src`:

```python
from agent.instruction import make_instruction_builder
```

If the code intentionally imports through `src`:

```python
from src.agent.instruction import make_instruction_builder
```

then Pyrefly needs the project root, not `src`, as a search path. Add this to `pyproject.toml`:

```toml
[tool.pyrefly]
search-path = ["."]
project-includes = ["src/**/*.py"]
```

Then restart the LSP:

```vim
:LspRestart
```

Why this exists: both import styles can be valid depending on how the project is packaged and launched. The editor cannot safely guess which one is intended across all projects, so the durable fix is to make the import layout explicit in the project config.

Also check that you are using `gd`, not `gD`. `gd` is definition; `gD` is declaration and may stop at the import statement.

If `dump-config` shows an editable install path like `__editable__...finder.__path_hook__`, static analyzers may not be able to follow that runtime import hook. Prefer a project config with an explicit `search-path`, or use an editable install mode that writes path-based `.pth` entries instead of import hooks.

---

# Jupyter Notebooks
## Jupytext
    pair a notebook: 
        `jupytext --set-formats ipynb,py:percent notebook.ipynb`
    synchronize the paired files: 
        `jupytext --sync notebook.py` (the inputs are loaded from the most recent paired file)
    convert a notebook in one format to another with: 
        `jupytext --to ipynb notebook.py` (use -o if you want a specific output file)
    pipe a notebook to a linter with e.g. 
        `jupytext --pipe black notebook.ipynb`

## Setup venv
```py
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
##
## uv
##
uv venv .venv --python 3.12
source .venv/bin/activate
uv pip install -r requirements.txt

``` 

## Requirements.txt
find errors in requirements
  ┌───────────────────────────────┬──────────────────────────────────────────────────────────────────────┐
  │            Command            │                              Behaviour                               │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────┤
  │ --only-binary :all: --dry-run │ Only considers pre-built wheels — surfaces missing wheels            │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────┤
  │ --dry-run (no flag)           │ Attempts source builds when no wheel found — surfaces build failures │
  └───────────────────────────────┴──────────────────────────────────────────────────────────────────────┘

```
pip install -r requirements.txt --only-binary :all: --dry-run 2>&1 | grep "No matching distribution"
pip install -r requirements.txt --dry-run 2>&1 | grep -A 5 "Failed to build"
```
You can also check a single package before committing to a version:

pip index versions grpcio  # lists all available versions
pip install grpcio==1.62.0 --only-binary :all: --dry-run  # checks if a specific version has a wheel

And to see exactly what wheel tags your current Python supports (useful for cross-referencing against PyPI):

pip debug --verbose


## Pycharm
Interpreter not recognized (verify files):
- `~/Library/Application Support/JetBrains/PyCharm2025.1/options/jdk.table.xml`
- `.idea/misc.xml`
