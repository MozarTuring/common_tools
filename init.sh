set -e


#cd /home/maojingwei/software
#tar -xvf git-2.32.0.tar.xz
#cd git-2.32.0
#make prefix=/home/maojingwei/installed/git all
#make prefix=/home/maojingwei/installed/git install
#echo "export PATH=\"/home/maojingwei/installed/git/bin:\$PATH\"" >> /home/maojingwei/.bashrc
#
#cd /home/maojingwei/.ssh
#ls
#ssh-keygen -t ed25519 -C "your_email@example.com"
#cat id_ed25519.pub


#echo "set completion-ignore-case on">>/home/maojingwei/.inputrc # source does not work, need to restart teminal

#cd /home/maojingwei/software/
#if [ -d "Python-3.8.16" ]; then
#    echo "clear last install"
#    rm -rf Python-3.8.16
#else
#    echo "no python dir"
#fi
#tar -xvf Python-3.8.16.tar.xz
#cd /home/maojingwei/software/Python-3.8.16
#./configure --prefix=/home/maojingwei/installed/python3.8.16 --enable-shared
#make && make install
#echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/home/maojingwei/installed/python3.8.16/lib" >> /home/maojingwei/.bashrc
#source /home/maojingwei/.bashrc  # need to execute outside
#mkdir -p /home/maojingwei/.config/pip
#echo "[global]
#index-url = https://pypi.mirrors.ustc.edu.cn/simple
#trusted-host=pypi.mirrors.ustc.edu.cn" > /home/maojingwei/.config/pip/pip.conf
#/home/maojingwei/installed/python3.8.16/bin/python3 -m pip install virtualenv


cd /home/maojingwei/software
#if [ -d "vim" ]; then
#    echo "clear last install"
#    cd vim/src
#    make uninstall
#    cd ../..
#    rm -rf vim
#    rm -rf /home/maojingwei/installed/vim
#else
#    echo "no vim dir"
#fi
#tar zxvf vim.tar.gz
#cd /home/maojingwei/software/vim
#./configure --with-features=huge --prefix=/home/maojingwei/installed/vim --enable-python3interp=dynamic --with-python3-config-dir=$(/home/maojingwei/installed/python3.8.16/bin/python3-config --configdir) --with-python3-command=/home/maojingwei/installed/python3.8.16/bin/python3
#make && make install
####echo "export PATH=/home/maojingwei/installed/vim/bin/:$PATH" >> /home/maojingwei/.bashrc # by this way, $PATH will be replaced by its value. so use the line below
#echo "export PATH=\"/home/maojingwei/installed/vim/bin/:\$PATH\"" >> /home/maojingwei/.bashrc # can not use ' after =
#echo "export VIMINIT='source /home/maojingwei/project/common_tools_for_centos/vimrc'" >> /home/maojingwei/.bashrc


#scp -r maojingwei@10.20.14.42:/home/maojingwei/.vim /home/maojingwei/

#cd /home/maojingwei/software
#tar -zxvf TensorRT-8.2.5.1.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz
#echo "export TENSORRT_HOME=\"/home/maojingwei/software/TensorRT-8.2.5.1\"
#export PATH=\"\$TENSORRT_HOME/bin:\$PATH\"
#export LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH:\$TENSORRT_HOME/lib\"
#export LD_INCLUDE_PATH=\"\$TENSORRT_HOME/include:\$LD_INCLUDE_PATH\"" >> /home/maojingwei/.bashrc
