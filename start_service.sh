set -e

#systemctl restart redis
#systemctl start redis.service


#yum install cockpit
#firewall-cmd --permanent --zone=public --add-service=cockpit
#firewall-cmd --reload
#systemctl start cockpit
#systemctl start cockpit.service
#systemctl status cockpit.service  # use port 9090 by default


# for debugpy
#firewall-cmd --zone=public --add-port=55678/tcp --permanent
#firewall-cmd --reload

#yum -y install vsftpd
#echo "anonymous_enable=NO\n \
#chroot_local_user=YES\n \
#allow_writeable_chroot=YES\n \
#userlist_enable=YES\n \
#userlist_file=/etc/vsftpd.userlist\n \
#userlist_deny=NO" >> /etc/vsftpd/vsftpd.conf
#firewall-cmd --permanent --zone=public --add-service=ftp
#firewall-cmd --reload
#semanage boolean -m ftpd_full_access --on
#systemctl start vsftpd

#yum install sshpass
#yum install sudo -y

# vncserver related staff
# windows client use tightvnc
#
# #  install vlc
#sudo yum install epel-release
#sudo yum install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
#sudo yum install vlc
