conda activate base
conda install jupyterlab

conda activate myenv
conda install ipykernel
python -m ipykernel install --user --name=myenv --display-name "Python (myenv)"



wait is a bash builtin, not a SLURM thing. It works on any backgrounded process. From bash's perspective, srun is just a child process like any other.

