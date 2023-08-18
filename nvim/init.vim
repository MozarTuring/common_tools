if has("win64")
    set runtimepath^=~/.mjw_vim_pack runtimepath+=~/.mjw_vim_pack/after
    let &packpath = &runtimepath
    source ~/project/common_tools_for_centos/vimrc
else
    set runtimepath^=/home/maojingwei/.mjw_vim_pack runtimepath+=/home/maojingwei/.mjw_vim_pack/after
    let &packpath = &runtimepath
    source /home/maojingwei/project/common_tools_for_centos/vimrc
endif
