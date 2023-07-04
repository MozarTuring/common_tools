set -e


cd /home/maojingwei/software
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.32.0.tar.xz
tar -xvf git-2.32.0.tar.xz
cd git-2.32.0
make prefix=/home/maojingwei/installed/git all
make prefix=/home/maojingwei/installed/git install
echo "export PATH=/home/maojingwei/installed/git/bin:$PATH" >> /home/maojingwei/.bashrc

cd /home/maojingwei/.ssh
ls
ssh-keygen -t ed25519 -C "your_email@example.com"
cat id_ed25519.pub


#echo "set completion-ignore-case on">>/home/maojingwei/.inputrc # source does not work, need to restart teminal

#scp maojingwei@10.20.14.42:/home/maojingwei/software/Python-3.8.16.tar.xz /home/maojingwei/software/
#cd /home/maojingwei/software/
#tar -xvf Python-3.8.16.tar.xz
#cd /home/maojingwei/software/Python-3.8.16
#./configure --prefix=/home/maojingwei/installed/python3.8.16 --enable-shared
#make && make install
#echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/home/maojingwei/installed/python3.8.16/lib" >> /home/maojingwei/.bashrc
#source /home/maojingwei/.bashrc  # need to execute outside


#scp -r maojingwei@10.20.14.42:/home/maojingwei/software/vim_bak /home/maojingwei/software/
#cd /home/maojingwei/software/
#cp -r vim_bak vim
#cd /home/maojingwei/software/vim
#./configure --with-features=huge --prefix=/home/maojingwei/installed/vim --enable-python3interp --with-python3-command=/home/maojingwei/installed/python3.8.16/bin/python3
#make && make install
#echo "export PATH=\"/home/maojingwei/installed/vim/bin/:\$PATH\"" >> /home/maojingwei/.bashrc
#echo "export VIMINIT='source /home/maojingwei/common_tools_for_centos/vimrc'" >> /home/maojingwei/.bashrc

#scp -r maojingwei@10.20.14.42:/home/maojingwei/.vim /home/maojingwei/
#scp maojingwei@10.20.14.42:/home/maojingwei/.vimrc /home/maojingwei/

#scp maojingwei@10.20.14.42:/home/maojingwei/software/cuda_11.4.0_470.42.01_linux.run /home/maojingwei/software/
#sub
#exit
