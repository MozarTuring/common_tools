conda activate base
conda install jupyterlab

conda activate myenv
conda install ipykernel
python -m ipykernel install --user --name=myenv --display-name "Python (myenv)"
