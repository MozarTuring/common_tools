set nocompatible              " be iMproved, required
filetype off                  " required

set runtimepath+=/home/maojingwei/.vim

"packadd flake8
execute pathogen#infect()

"call plug#begin()
"Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
"call plug#end()

set nocompatible
syntax on
filetype plugin indent on
set ic
set hlsearch
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,GB2312,big5
set cursorline
set autoindent
set smartindent
set scrolloff=4
set showmatch
set nu
set t_Co=256 

let python_highlight_all=1
au Filetype python set tabstop=4
au Filetype python set softtabstop=4
au Filetype python set shiftwidth=4
"au Filetype python set textwidth=79
au Filetype python set expandtab
"au Filetype python set autoindent
au Filetype python set fileformat=unix
autocmd Filetype python set foldmethod=indent
autocmd Filetype python set foldlevel=99

syntax enable
set background=light
@REM colorscheme solarized


@REM if has('gui_running')
@REM   set background=dark
@REM   colorscheme solarized
@REM else
  
@REM endif

"maj <F3> :NERDTreeMirror<CR>

"map ,t :NERDTreeToggle<CR>

map ,t :NERDTreeFocus<CR>
let NERDTreeShowHidden=1


" Below is my design


function! NERDTreeYankCurrentNode()
    let n = g:NERDTreeFileNode.GetSelected()
    if n != {}
        let tmp_path = n.path.str()
        echo tmp_path
        call setreg('"', tmp_path)
    endif
endfunction
nmap yp :call NERDTreeYankCurrentNode()<cr>


func! Comment() range
    "echo line("v")
    "if multiple lines are chosen,then the above line will be executed multiple
    "times
    "echo line("v")[0]
    "echo line("v")[1]
    "let line_start = line_num_ls[0]
    "let line_end = line_num_ls[-1]
    "echo line_start
    "echo line_end
"    echo a:firstline
"    firstline 永远是小的那个，no matter select up to down or down to up
"    echo a:lastline
"    echo "start"
    let prefix = join([a:firstline,a:lastline],",")
"    echo prefix
"    let empty_char = [" "]
    let first_line_char = getline(a:firstline)
    for first_char in first_line_char
        if first_char != " "
            break
        endif
    endfor
"    echo &filetype
    let filetype_ls1 = ["python","sh", "dockerfile"]
    if index(filetype_ls1, &filetype)>=0 && first_char=="#"
        exec join([prefix,"s/#//"])
        exec "noh"
    elseif index(filetype_ls1, &filetype)>=0 && first_char!="#"
        exec join([prefix,"s/^/#/"])
        exec "noh"
    elseif &filetype == "html" && first_line_char[:1] != "<!"
        echo "here"
        exec a:firstline."s/^/<!--/"
        exec a:lastline."s/$/-->/"
    elseif &filetype == "html" && first_line_char[:1] == "<!"
        exec a:firstline."s/<!--//"
        exec a:lastline."s/-->//"
    elseif &filetype=="vim" && first_char=='"'
"        echo "3"
        exec join([prefix,'s/^"//'])
        exec "noh"
    elseif &filetype=="vim" && first_char!='"'
"        echo "4"
        exec join([prefix,'s/^/"/g'])
"        exec "noh"
    endif
endfunc
vnoremap <silent> # :call Comment()<CR>
nmap <silent> # :call Comment()<CR>
vnoremap <C-s> "hy:%s/<C-r>h//gc<left><left><left>
" <left> means cursor moves towards left; <C-r>h means use content in h register

func! GetAbsPath()
let cur_dir = getcwd()
let cur_file_path=getreg('%')
if cur_file_path[0]=="/"
    let abs_path = cur_file_path
else
    let abs_path = join([cur_dir,cur_file_path],"/")
endif
echo cur_dir
echo cur_file_path
echo abs_path
call setreg('a', abs_path)
return abs_path
endfunc
nmap <c-y> :call GetAbsPath()<cr>


func! KillPid()
let inp_pids = input("Please input pid:\n")
let tmp_command = "silent !kill -9 ". inp_pids
exec tmp_command
exec "q"
redraw
endfunc


func! CompileRunGcc(inp_mode)
exec "w"
" 上面这相当于 :w<CR> 也就是保存文件的意思 
let abs_path = GetAbsPath()
let abs_path_split = split(abs_path,"/")
let abs_dir = "/" . join(abs_path_split[:-2],"/")
let cur_name = split(abs_path_split[-1],'\.')[0]
" notice that the above sep must be in single quote
"echo abs_path_split[-1]
echo abs_dir
echo cur_name
"return 0
if &filetype == 'sh'
    if index(cur_name, "_run") >= 0
        let inp_args = input("input args:\n")
        exec "!bash % " . inp_args
    else
        exec "!bash %" 
    endif
elseif &filetype == 'python'
    let shell_path = "/home/maojingwei/project/common_tools_for_centos/run.sh"
    "echo "start"
    "echo "!bash "+shell_path+" %" 字符串没有加法运算
"    let inp_dir = input("input python file dir:\n")
"    if len(inp_dir) !=0
"        exec "!ls ". inp_dir
"        let inp_name = input("input python filename:\n")
"        let abs_path = inp_dir. "/". inp_name
"    endif

    if a:inp_mode == "d"
"        exec "normal oimport ipdb;ipdb.set_trace()"
"        exec "w"
        let tmp_command = join(["term bash",shell_path,abs_path,"debug"], " ")
        exec tmp_command 
    elseif a:inp_mode == "r"
        let tmp_command = join(["term bash",shell_path,abs_path,"run"], " ")
        exec tmp_command 
    else
        let cur_time = localtime()
        let tmp_command = join(["silent !bash",shell_path,abs_path,"nohup",cur_time], " ")
        exec tmp_command 
        exec "tabnew " . abs_dir . "/jwlogs/" . cur_name . "_". cur_time .".log"
        redraw
    endif
elseif &filetype == 'vim'
	" 注意首次写source不了最新的，因为要source之后才能get到最新的内容，而你的新内容
    " 因为source 的时候，vimrc文件还没保存，所以source的还是旧版本的
	exec "source %"
	echo "done sourcing"
endif
endfunc
nmap fr :call CompileRunGcc("r")<CR>
nmap fd :call CompileRunGcc('d')<CR>
nmap fn :call CompileRunGcc('n')<CR>

func! GetPid()
    exec "silent !bash /home/maojingwei/project/common_tools_for_centos/get_pid.sh"
    exec "tabnew /home/maojingwei/tmp.pid"
    redraw
    call KillPid()
endfunc
nmap <silent> gp :call GetPid()<cr>


func! InsertIpdb()
    exec "normal oimport ipdb;ipdb.set_trace()"
endfunc
nmap gi :call InsertIpdb()<cr>


func! PasteToNewLine()
    let content = getreg('"')
    exec "normal o".content
endfunc
nmap ;p :call PasteToNewLine()<cr>


func! MyRefresh()
    exec "w"
    exec "e!"
endfunc
au InsertEnter * :call MyRefresh()


nmap gr :!grep -n 
nmap tn :tabnew 
nmap gh :!bash /home/maojingwei/run.sh 
nmap ,f :NERDTreeFind<CR>

nmap ;e :e<cr>
nmap ;q :q<cr>
nmap ;w :w<cr>
nmap ;s :source /home/maojingwei/project/common_tools_for_centos/vimrc<cr>
"noremap ;s <c-w>w hard to remap, just need to practice your fingure get used to this key combination
nmap gj :call jedi#goto()<CR>
let g:jedi#use_tabs_not_buffers = 1
nmap gl :!ls 
" the second key should be press fast after the first key in order to make the
" key combination take effect

noremap gt gT
noremap gy gt

set autoread " can autoread after execute some outside command like !bash
set laststatus=2
set statusline=%f\ [POS=%04l,%04v]
set backspace=indent,eol,start
set expandtab
set tabstop=4
set shiftwidth=4
set wrap
let g:jedi#popup_on_dot = 0
"au FocusGained * :e<cr>
"must restart vim to make the above setting work
