if has("win64")
    set runtimepath^=~/.mjw_vim_pack runtimepath+=~/.mjw_vim_pack/after
    let &packpath = &runtimepath
else
    set runtimepath^=$MJWHOME/mjw_tmp_jwm/vim_pack runtimepath+=$MJWHOME/mjw_tmp_jwm/vim_pack/after
    let &packpath = &runtimepath
endif

set nocompatible              " be iMproved, required
filetype off                  " required

"execute pathogen#infect()
"packadd emmet-vim
"packadd fugitive
"packadd jedi-vim
"packadd nerdtree

"curl -fLo /home/maojingwei/mjw_tmp_jwm/vim_pack/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
call plug#begin('/home/maojingwei/mjw_tmp_jwm/vim_pack/bundle')
Plug 'https://github.com/vim-airline/vim-airline.git', { 'on':[]}
"d9f42cb46710e31962a9609939ddfeb0685dd779
Plug 'https://github.com/pocco81/auto-save.nvim.git'
"979b6c82f60cfa80f4cf437d77446d0ded0addf0
Plug 'https://github.com/mattn/emmet-vim.git'
"def5d57a1ae5afb1b96ebe83c4652d1c03640f4d
Plug 'https://github.com/tpope/vim-fugitive.git'
"dac8e5c2d85926df92672bf2afb4fc48656d96c7
Plug 'https://github.com/Yggdroot/indentLine.git'
"b96a75985736da969ac38b72a7716a8c57bdde98
Plug 'https://github.com/davidhalter/jedi-vim.git'
"9bd79ee41ac59a33f5890fa50b6d6a446fcc38c7
Plug 'https://github.com/preservim/nerdtree.git'
"f3a4d8eaa8ac10305e3d53851c976756ea9dc8e8
call plug#end()

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

function! Clearnvim()
    execute "!rm /home/maojingwei/.local/state/nvim/swap/*"
endfunction
nmap ff :call Clearnvim()<cr>


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
    
    if index(filetype_ls2, &filetype)>=0
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
    elseif &filetype=="lua"
        if first_char == "-"
            let tmp_command_ls = [join([prefix,'s/^--//'])]
        else
            let tmp_command_ls = [join([prefix,'s/^/--/g'])]
        endif
    elseif &filetype=="vim"
        if first_char=='"'
            let tmp_command_ls = [join([prefix,'s/^"//'])]
        else
            let tmp_command_ls = [join([prefix,'s/^/"/g'])]
        endif
    else
        if first_char=="#"
            let tmp_command_ls = [join([prefix,"s/#//"])]
        else
            let tmp_command_ls = [join([prefix,"s/^/#/"])]
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

function! GoToTabByName(tabname)
    let tab_count = tabpagenr('$')
    for i in range(1, tab_count)
        let bufname = bufname(tabpagebuflist(i)[0])
        echo i
        echo "tabname ". bufname
        if bufname == a:tabname
            execute "tabn " . i
            return "success"
        endif
    endfor
    return "fail"
endfunction


func! OpenLog(inp)
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    let cur_file = abs_path_split[-1]
    let log_prefix = abs_dir. "/".cur_file. "_log"

    let tmp_path = log_prefix .a:inp
    echo tmp_path
"    let window_count = winnr('$') - 1    
    if filereadable(tmp_path)
"        if GoToTabByName(tmp_path) == "fail"
        let cur_tab_nr = tabpagenr()
        let tab_window_count = tabpagewinnr(cur_tab_nr, "$")    
        if tab_window_count == 1
            execute "botright vsplit " . tmp_path
        endif
    endif
    redraw
endfunc
nmap fl0 :call OpenLog(0)<CR>
nmap fl1 :call OpenLog(1)<CR>
nmap fl2 :call OpenLog(2)<CR>





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



func! GetCommand(strStart, strEnd)
let shell_start_line = search(a:strStart, 'b')
let shell_end_line = search(a:strEnd, 'b')
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
let stop_command = ""
while ind < len(content_ls)
    let ele = content_ls[ind]
    if "stop," == ele[:4]
        let stop_command = ele[5:]
    endif
    if "line," == ele[:4]
        let ele_split = split(ele,",")
        let command_ls = content_ls[ind+1:ind+ele_split[1]]
        break
    endif
    let ind += 1
endwhile
if len(command_ls) == 0
    let command_ls = [""]
endif
return [l:command_ls, l:stop_command]
endfunc


func! CompileRunGcc(inp_mode)
    exec "e"
    let [abs_path, abs_dir, cur_name, abs_path_split] = CompileStop()
    let cur_file = abs_path_split[-1]
    let log_prefix = abs_dir. "/". cur_file. "_log"

    let count = 0

    if &filetype == 'sh'
        let [args_ls, stop_command] = GetCommand(':<<EOF', 'EOF')
        for ele in args_ls
            exec "!nohup bash ". abs_path. " ". ele. " >" .log_prefix .count. " 2>&1 &"
            let count += 1
        endfor
    elseif &filetype == 'python'
        let line1 = getline(1)
        if line1[:2] == "#!/"
            let cur_python = line1[2:]
        else
            let cur_python = substitute(abs_dir, 'project', 'mjw_tmp_jwm/project', 'g')
            let cur_python = cur_python. "/condaenv/bin/python"
        endif
        let [args_ls, stop_command] = GetCommand('"""run_mjw', 'run_jwm"""')
        for ele in args_ls
            if a:inp_mode == "d"
                let tmp_command = "!nohup ". cur_python. " -m debugpy --listen localhost:35678 --wait-for-client ". abs_path. " ". ele. " >" .log_prefix .count. " 2>&1 &"
            elseif a:inp_mode == "r"
                let tmp_command = "!nohup ". cur_python. " ". abs_path. " ". ele. " >" .log_prefix .count. " 2>&1 &"
            endif
            let count += 1
            exec tmp_command
        endfor
    else
        echo "compile does not support this filetype"
    endif
    call getchar()
    call OpenLog(0)
endfunc

nmap fr :call CompileRunGcc("r")<CR>
nmap fd :call CompileRunGcc("d")<CR>


func! CompileStop()
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    if &filetype == 'sh'
        let [args_ls, stop_command] = GetCommand(':<<EOF', 'EOF')
        if strlen(stop_command) != 0
            exec "!bash /home/maojingwei/project/common_tools_for_centos/kill_pid.sh ". stop_command
        endif
    elseif &filetype == 'python'
        exec "!bash /home/maojingwei/project/common_tools_for_centos/kill_pid.sh ". abs_path 
    endif
    return [abs_path, abs_dir, cur_name, abs_path_split]
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



func! MyWriteFile()
    exec "w"
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    if abs_dir == "/home/maojingwei/project/common_tools_for_centos"
        exec "!sshpass -p 9213fCOW scp ". abs_path " maojingwei@10.20.14.43:". abs_path
        exec "!sshpass -p 9213 scp ". abs_path " maojingwei@120.79.52.236:". abs_path
    elseif abs_dir == "/home/maojingwei/project/attendance_backend"
        exec "!sshpass -p 9213 scp ". abs_path " maojingwei@120.79.52.236:". abs_path
    endif
endfunc


func! MyRefreshFile()
    exec "e"
    exec "normal G"
endfunc



function! ClearFile()
    execute "%delete _"
endfunction


function! MyTabLine()
    let s = ''
    let tnum = tabpagenr() " 当前tab编号
    let n = tabpagenr('$') " 所有tab数量
    echo "n ".n
    for i in range(1, n)
        let tmp_winnr = tabpagewinnr(i)
        echo "tmp_winnr ".tmp_winnr
"        let filename = bufname(winbufnr(tabpagewinnr(i)))
"        echo "tabline ".filename
"        if i == tnum
"            let s .= '%#TabLineSel#'.i.' '.filename. ' %#TabLineSel#'
"        else
"            let s .= '%#TabLine#'.i.' '.filename. ' %#TabLine#'
"        endif
    endfor
    return s
endfunction

"set tabline=%!MyTabLine()

func! CheckMyProcess()
    exec "!ps -ef|grep mjw_tmp_jwm"
endfunc
nmap ck :call CheckMyProcess()<cr>



nmap gr :!grep -n 
nmap ,f :NERDTreeFind<CR>

nmap ;d :call ClearFile()<cr>
nmap ;q :q<cr>
nmap ;a :qall<cr> 
" 这会导致;q 的响应变慢，需要等待一会儿以确定确实是;q而不是;qall
nmap ;w :call MyWriteFile()<cr>
nmap <space> :call MyRefreshFile()<cr>
nmap <2-LeftMouse> :call CompileRunGcc('r')<cr>
nmap ;s :source /home/maojingwei/project/common_tools_for_centos/vimrc<cr>
"noremap ;s <c-w>w hard to remap, just need to practice your fingure get used to this key combination
nmap gj :call jedi#goto()<CR>
let g:jedi#use_tabs_not_buffers = 1
" the second key should be press fast after the first key in order to make the key combination take effect

noremap gt gT
noremap gy gt

set autoread " can autoread after execute some outside command like !bash
set laststatus=2
set statusline=%f\ [POS=l,v]
set backspace=indent,eol,start
set expandtab
set tabstop=4
set shiftwidth=4
set wrap
let g:jedi#popup_on_dot = 0
"au FocusGained * :e<cr>
"must restart vim to make the above setting work

let g:vimtex_view_general_viewer = 'SumatraPDF'
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

"set mouse=
set mouse=a


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

