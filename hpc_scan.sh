brew install --cask macfuse
brew install gromgit/fuse/sshfs
brew install gdu


mkdir m/
sshfs berzeliusampere:/proj/berzelius-aiics-real/users/x_jinma m/
gdu -o berzelius-$(date +%F).gdu m/
umount m/

