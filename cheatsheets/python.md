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
