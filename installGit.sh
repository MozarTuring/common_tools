#git --version
#yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel asciidoc
#yum install gcc perl-ExtUtils-MakeMaker
#yum remove git

cd /home/maojingwei/mjw_tmp_jwm/software
tar -xvf git-2.32.0.tar.xz
# yum install make
cd git-2.32.0
mkdir -p ~/installed/git
make prefix=~/installed/git all
make prefix=~/installed/git install

#cd /home/maojingwei/.ssh
#ls
#ssh-keygen -t ed25519 -C "your_email@example.com"
#cat id_ed25519.pub

cd /home/maojingwei/mjw_tmp_jwm/installed/git; bin/git clone git@github.com:MozarTuring/common_tools_for_centos.git /home/maojingwei/project/common_tools_for_centos