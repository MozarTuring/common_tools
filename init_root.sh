set -e

#useradd maojingwei
#passwd maojingwei


#### for git
#git --version
#yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel asciidoc
#yum install gcc perl-ExtUtils-MakeMaker
#yum remove git

## for python
#yum -y install zlib zlib-devel bzip2 bzip2-devel ncurses ncurses-devel readline readline-devel openssl openssl-devel openssl-static xz lzma xz-devel sqlite sqlite-devel  gdbm gdbm-devel tk tk-devel libffi libffi-devel gcc make
#exit

#lsmod | grep nouveau
#echo "blacklist nouveau
#options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
#mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
#dracut /boot/initramfs-$(uname -r).img $(uname -r)
#reboot
#cd /home/maojingwei/software/
#sh NVIDIA-Linux-x86_64-535.54.03.run --kernel-source-path=/usr/src/kernels/kernel_there # if kernel not found error occurs, check uname -r and ls /usr/src/kernels
#sh cuda_11.4.0_470.42.01_linux.run

#wget https://repo.mysql.com/mysql80-community-release-el7-1.noarch.rpm
#yum localinstall mysql80-community-release-el7-1.noarch.rpm
#yum install mysql-community-server -y --nogpgcheck
#systemctl stop mysqld
#rm -rf /var/lib/mysql/*
#systemctl start mysqld
#grep "A temporary password" /var/log/mysqld.log
#mysql_secure_installation


#yum install -y nginx
#rpm -qa firewalld # expected output: firewalld-0.6.3-2.el7_7.2.noarch
#systemctl status firewalld
#systemctl start firewalld
#firewall-cmd --permanent --zone=public --add-service=http
#firewall-cmd --permanent --zone=public --add-service=https
#firewall-cmd --reload
#setenforce 0 # if 403 forbidden, try this. this will close SELinux temporarily
##cp /home/maojingwei/project/common_tools_for_centos/nginx.conf /etc/nginx/nginx.conf


#echo "
#RSAAuthentication yes
#
#PubkeyAuthentication yes" >> /etc/ssh/sshd_config
#systemctl restart sshd
#systemctl status sshd


#yum install nodejs  npm -y
#npm install -g vue-cli
