jupyter notebook --generate-config
jupyter notebook password
cp ~/project/common_tools/jupyter_notebook_config.py ~/.jupyter/jupyter_notebook_config.py
cat ~/.jupyter/jupyter_notebook_config.json >> ~/.jupyter/jupyter_notebook_config.py
jupyter notebook --config=~/project/common_tools/jupyter_notebook_config.py --ip=0.0.0.0 --port=8888 --no-browser
