if has("win64")
    set runtimepath^=~/.mjw_vim_pack runtimepath+=~/.mjw_vim_pack/after
    let &packpath = &runtimepath
else
    set runtimepath^=$MJWHOME/mjw_tmp_jwm/vim_pack runtimepath+=$MJWHOME/mjw_tmp_jwm/vim_pack/after
    let &packpath = &runtimepath
endif


set nocompatible              " be iMproved, required
filetype off                  " required


execute pathogen#infect()
"packadd emmet-vim
"packadd fugitive
"packadd jedi-vim
"packadd nerdtree

"call plug#begin()
"Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
"call plug#end()

syntax on
"colorscheme monokai
"colorscheme tokyonight-day
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


function! Yankpath()
    if g:NERDTree.IsOpen()
        let n = g:NERDTreeFileNode.GetSelected()
        if n != {}
            let tmp_path = n.path.str()
            echo tmp_path
            call setreg('"', tmp_path)
        endif
    else
        call GetAbsPath("b")
    endif
endfunction
nmap yp :call Yankpath()<cr>


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
    echo &filetype
    let filetype_ls1 = ["python","sh", "dockerfile", "yaml"]
    let filetype_ls2 = ["html", "vue"]
    let filetype_ls3 = ["javascript", "css"]
    if index(filetype_ls1, &filetype)>=0
        if first_char=="#"
            let tmp_command_ls = [join([prefix,"s/#//"])]
        else
            let tmp_command_ls = [join([prefix,"s/^/#/"])]
        endif
    elseif index(filetype_ls2, &filetype)>=0
        if first_line_char[:1] == "<!"
            let tmp_command_ls = [a:firstline."s/<!--//", a:lastline."s/-->//"]
        else
            let tmp_command_ls = [a:firstline."s/^/<!--/", a:lastline."s/$/-->/"]
        endif
    elseif index(filetype_ls3, &filetype)>=0
        if first_line_char[:1] == "/*"
            let tmp_command_ls = [a:firstline."s/\\/\\*//", a:lastline."s/\\*\\///"]
        else
            let tmp_command_ls = [a:firstline."s/^/\\/\\*/", a:lastline."s/$/\\*\\//"]
        endif
    elseif &filetype=="vim"
        if first_char=='"'
            let tmp_command_ls = [join([prefix,'s/^"//'])]
        else
            let tmp_command_ls = [join([prefix,'s/^/"/g'])]
        endif
    endif
    for ele in tmp_command_ls
        exec ele
    endfor
    exec "noh"
endfunc
vnoremap <silent> # :call Comment()<CR>
nmap <silent> # :call Comment()<CR>
vnoremap <C-s> "hy:%s/<C-r>h//gc<left><left><left>
" <left> means cursor moves towards left; <C-r>h means use content in h register

func! GenerateCode() range
    let v = @"
    let tmp_list = split(v, ",")
    let all_str = "for k, v in kwargs.items():"
    for tmp_ele in tmp_list
        let ele_list = split(tmp_ele, "\"")
        echo ele_list
        let ele = ele_list[1]
        let tmp_str = ele. " = kwargs.get(\"" . ele. "\", None)"
        let all_str = all_str . "\n". tmp_str
    endfor
    let @"=all_str
endfunc
nmap fg :call GenerateCode()<CR>


func! GetAbsPath(inp_mode)
    let cur_dir = getcwd()
    let cur_file_path = getreg('%')
    if cur_file_path[0]=="/"
        let tmp_abs_path = cur_file_path
    else
        let tmp_abs_path = join([cur_dir,cur_file_path],"/")
    endif
    let tmp_abs_path_split = split(tmp_abs_path,"/")
    let tmp_abs_dir = "/" . join(tmp_abs_path_split[:-2],"/")
    let ttmp_abs_dir = system("cd ".tmp_abs_dir."; pwd")
    let abs_dir = strpart(ttmp_abs_dir,0,strlen(ttmp_abs_dir)-1)
    let abs_path = abs_dir."/".tmp_abs_path_split[-1]

    let abs_path_split = split(abs_path,"/")
    let cur_name = split(abs_path_split[-1],'\.')[0]
    " notice that the above sep must be in single quote
    if a:inp_mode=="a"
        return [l:abs_path,l:abs_dir,l:cur_name,l:abs_path_split]
    else
        echo "here"
        call setreg('"', abs_path)
        return abs_path
    endif
endfunc

func! OpenLog()
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    let tmp_logs_prefix = abs_dir. "/mjw_tmp_jwm/log_".cur_name

    let ele = 0
    while ele < 8
        let tmp_path = tmp_logs_prefix. ele. ".log"
        echo tmp_path
        if filereadable(tmp_path)
            exec "tabnew " . tmp_path
            let ele += 1
        else
            break
        endif
    endwhile
    redraw
endfunc
nmap fl :call OpenLog()<CR>





func! KillPid()
let inp_pids = input("Please input pid:\n")
let tmp_command = "silent !kill -9 ". inp_pids
exec tmp_command
exec "q"
redraw
endfunc



func! CreateDir(inp_dir)
let result = system("test -d ".a:inp_dir)
if result == 0
    let tmp_command = "mkdir -p ". a:inp_dir
    let tmp_ret = system(tmp_command)
endif
endfunc


func! CompileRunGcc(inp_mode)
exec "e"
let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
call CreateDir(abs_dir. "/mjw_tmp_jwm")
let tmp_commands_prefix = abs_dir. "/mjw_tmp_jwm/command_".cur_name
let tmp_logs_prefix = abs_dir. "/mjw_tmp_jwm/log_".cur_name

if &filetype == 'sh'
    if a:inp_mode == "r"
        exec "!bash ". abs_path
    elseif a:inp_mode == "n"
        exec "!nohup bash ". abs_path. " >" .tmp_logs_prefix. "0.log 2>&1 &"
    endif
elseif &filetype == 'python'
    let shell_start_line = search('"""shell_run_mjw', 'b')
    let shell_end_line = search('shell_run_mjw"""')
    let content_ls = []
    if shell_start_line != 0
        while shell_start_line < shell_end_line-1
            let shell_start_line += 1
            let cur_content = getline(shell_start_line)
            let content_ls += [cur_content]
        endwhile
    endif
    let ind = 0
    let command_ls = []
    let source_path = ""
    while ind < len(content_ls)
        let ele = content_ls[ind]
        if "source " == ele[:6]
            let source_path = ele[7:]
        endif
        if "$#pre," == ele[:5]
            let ele_split = split(ele,",")
            let end_pos = ind+ele_split[1]
            let pre_command_ls = content_ls[ind+1:end_pos]
            let pre_command_path = tmp_commands_prefix. "_Pre". ".sh"
            call writefile(pre_command_ls, pre_command_path)
            exec "!bash ".pre_command_path. ">" .tmp_logs_prefix. "0.log 2>&1"
            let ind = end_pos
        elseif "$#line," == ele[:6]
            let ele_split = split(ele,",")
            let command_ls = content_ls[ind+1:ind+ele_split[1]]
            break
        endif
        let ind += 1
    endwhile
    if len(command_ls) == 0
        let command_ls = [""]
    endif

    let command_path = tmp_commands_prefix. "_Run". ".txt"
    let new_command_ls = []
    let count = 0
    for ele in command_ls
        if a:inp_mode == "r"
            let new_command_ls += ["python ". abs_path. " ". ele]
        elseif a:inp_mode == "n"
            let new_command_ls += ["nohup python ". abs_path. " ". ele. " >" .tmp_logs_prefix.count.".log 2>&1 &"]
        endif
        let count += 1
    endfor
    call writefile(new_command_ls, command_path)

    let stop_path = tmp_commands_prefix . "_Stop.txt"
    if a:inp_mode == "n"
        exec "!bash /home/maojingwei/project/common_tools_for_centos/kill_pid.sh ". stop_path
    endif
    call writefile([abs_path], stop_path)

    exec "!bash /home/maojingwei/project/common_tools_for_centos/run.sh ". abs_path . " ". command_path. " ". source_path 
    
elseif &filetype == 'vim'
	" 注意首次写source不了最新的，因为要source之后才能get到最新的内容，而你的新内容
    " 因为source 的时候，vimrc文件还没保存，所以source的还是旧版本的
	exec "source %"
	echo "done sourcing"
endif

if a:inp_mode == "n"
    call OpenLog()
    redraw
endif

endfunc
nmap fr :call CompileRunGcc("r")<CR>
nmap fn :call CompileRunGcc("n")<CR>


func! CompileStop()
let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
let tmp_commands_prefix = abs_dir. "/mjw_tmp_jwm/command_".cur_name
let stop_path = tmp_commands_prefix . "_Stop.txt"
if &filetype == 'python'
    exec "!bash /home/maojingwei/project/common_tools_for_centos/kill_pid.sh ". stop_path
endif
endfunc
nmap fk :call CompileStop()<CR>


func! GetPid()
    exec "silent !bash /home/maojingwei/project/common_tools_for_centos/get_pid.sh"
    exec "tabnew /home/maojingwei/tmp.pid"
    redraw
"    call KillPid()
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


"func! MyRefresh()
"    exec "w"
"    exec "e!"
"endfunc
"au InsertEnter * :call MyRefresh()


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

let g:vimtex_view_general_viewer = 'SumatraPDF'
tnoremap <esc> <c-\><c-n>
"switch from terminal mode to normal mode
"let g:clipboard = {
"          \   'name': 'myClipboard',
"          \   'copy': {
"          \      '+': ['tmux', 'load-buffer', '-'],
"          \      '*': ['tmux', 'load-buffer', '-'],
"          \    },
"          \   'paste': {
"          \      '+': ['tmux', 'save-buffer', '-'],
"          \      '*': ['tmux', 'save-buffer', '-'],
"          \   },
"          \   'cache_enabled': 1,
"          \ }


if has("unnamedplus")
    set clipboard=unnamedplus
else
    set clipboard=unnamed
endif

set mouse=


nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

let g:telescope_root_path = '/home/maojingwei/project'

let NERDTreeQuitOnOpen=1


nnoremap <M-1> 1gt

nnoremap <M-2> 2gt

nnoremap <M-3> 3gt

nnoremap <M-4> 4gt

nnoremap <M-5> 5gt

nnoremap <M-6> 6gt

nnoremap <M-7> 7gt

nnoremap <M-8> 8gt

nnoremap <M-9> 9gt

nnoremap <M-0> :tablast<CR>
