#lsmod | grep nouveau
#echo "blacklist nouveau
#options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
#mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
#dracut /boot/initramfs-$(uname -r).img $(uname -r)
#reboot
#yum groupinstall "Development Tools"
yum install kernel-devel kernel-headers -y
#yum install asciidoc audit-libs-devel bash bc binutils binutils-devel bison diffutils elfutils
#yum install elfutils-devel elfutils-libelf-devel findutils flex gawk gcc gettext gzip hmaccalc hostname java-devel
#yum install m4 make module-init-tools ncurses-devel net-tools newt-devel numactl-devel openssl
#yum install patch pciutils-devel perl perl-ExtUtils-Embed pesign python-devel python-docutils redhat-rpm-config
#yum install rpm-build sh-utils tar xmlto xz zlib-devel
cd /home/maojingwei/software/
sh NVIDIA-Linux-x86_64-535.54.03.run
#sh cuda_11.4.0_470.42.01_linux.run 
