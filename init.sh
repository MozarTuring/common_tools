set -e

#useradd maojingwei
#passwd maojingwei

#su
#yum -y install zlib zlib-devel bzip2 bzip2-devel ncurses ncurses-devel readline readline-devel openssl openssl-devel openssl-static xz lzma xz-devel sqlite sqlite-devel  gdbm gdbm-devel tk tk-devel libffi libffi-devel gcc make
#yum install sudo -y
#echo "\nmaojingwei ALL=(ALL)    ALL" >> /etc/sudoers
#exit

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
