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
