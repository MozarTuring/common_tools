# ---- quiet for non-interactive shells (scp/rsync) ----
case $- in
    *i*) ;;
      *) return;; # stop going down if non-interactive
esac
# -----------------------------------------------------
#
# manually add the above to the top of .bashrc

# init_nvim.sh will add source ~/project/common_tools/bash_profile to the bottom of file ~/.bash_profile on macos or ~/.profile on ubuntu

export PATH="$HOME/jwSoftware/nvim/bin:$PATH"

