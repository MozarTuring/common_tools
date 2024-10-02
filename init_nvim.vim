
" Below is my design

function! Clswap()
    execute "!rm ~/.local/state/nvim/swap/*"
endfunction
nmap cls :call Clswap()<cr>


"function! Yankpath()
"    let tmp_path = ""
"    if g:NERDTree.IsOpen()
"        let n = g:NERDTreeFileNode.GetSelected()
"        if n != {}
"            let tmp_path = n.path.str()
"            echo tmp_path
"        endif
"    else
"        let tmp_path = GetAbsPath("b")
"    endif
"    echo 'h'
"    call setreg('"*', tmp_path)
"endfunction
"nmap yp :call Yankpath()<cr>


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
    redraw
endfunc
vnoremap <silent> # :call Comment()<CR>
nmap <silent> # :call Comment()<CR>

func! MyReplace()
    normal! gv"ay 
" not working without gv
    let tmp = @a
    echo tmp
    let tmp = substitute(tmp, '"', '\\"', 'g')
    echo tmp
    let tmp_rep = input("substitute with:")
    let tmp_command = ":%s/". tmp. "/".tmp_rep."/gc"
    echo tmp_command
    exec tmp_command
"    call setreg('a', tmp)
"    normal! :%s/<C-r>a//gc
endfunc
vnoremap <C-s> :call MyReplace()<CR>
" <left> means cursor moves towards left; <C-r>h means use content in h register


"func! Jwcl()
"    let current_date = strftime("%Y%m%d_%H%M%S")
"    let tmp = 'jwcl("'. current_date. '")'
"    execute "normal! O" . tmp
"    normal! <C-l>
"    normal! gl
"endfunc
"nmap fj :call Jwcl()<CR>


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
        return [abs_path,abs_dir,cur_name,abs_path_split]
    else
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
"    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
"    let cur_file = abs_path_split[-1]
"    let log_prefix = abs_path. $jwPlatform

"    let tmp_path = log_prefix .a:inp
"    let tmp_path = getline(1)
    let tmp_path = getline('.')
    echo tmp_path
    let tmp_path = tmp_path[5:strlen(tmp_path)-2]. '/log.txt'
    echo tmp_path
"    let window_count = winnr('$') - 1
    if filereadable(tmp_path)
"        if GoToTabByName(tmp_path) == "fail"
        let cur_tab_nr = tabpagenr()
        let tab_window_count = tabpagewinnr(cur_tab_nr, "$")
"        if tab_window_count == 1
"            execute "botright split " . tmp_path
"        endif
        execute "botright vsplit " . tmp_path
"        execute "topleft split " . tmp_path
        normal! ,f
    endif
    redraw
endfunc
"nmap fl :call OpenLog("")<CR>





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
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    let cur_file = abs_path_split[-1]
    let cur_dir = abs_path_split[-2]
    let log_prefix = abs_dir. "/". cur_file. "_log"

    let tmp = "!jwrun ". cur_dir. "/". cur_file
    exec tmp
    call OpenLog("")
    redraw
endfunc

nmap fr :call CompileRunGcc("r")<CR>


func! CompileStop()
    let [abs_path, abs_dir, cur_name, abs_path_split] = GetAbsPath("a")
    if &filetype == 'sh'
        let [args_ls, stop_command] = GetCommand(':<<EOF', 'EOF')
        if strlen(stop_command) != 0
            exec "!jwkill ". stop_command
        endif
    elseif &filetype == 'python'
        exec "!jwkill ". abs_path
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


"nmap gr :!grep -n
nmap ,f :NERDTreeFind<CR>

"nmap ;d :call ClearFile()<cr>
nmap ;q :wq<cr>
nmap ;a :wqall<cr>
" 这会导致;q 的响应变慢，需要等待一会儿以确定确实是;q而不是;qall
nmap ;e :call MyRefreshFile()<cr>
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

set clipboard+=unnamedplus
let g:clipboard = {
            \   'name': 'WslClipboard',
            \   'copy': {
            \      '+': 'clip.exe',
            \      '*': 'clip.exe',
            \    },
            \   'paste': {
            \      '+': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            \      '*': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            \   },
            \   'cache_enabled': 0,
            \ }


"function! MyCustomFinder()
"  let opts = {
"  \ 'prompt_title': 'Custom File Finder',
"  \ 'ignore_patterns': ['111mjw_tmp_jwm', 'node_modules', 'build', 'dist', '*.log', '*.tmp'],
"  \ 'hidden': 1
"  \ }
"  call telescope#builtin#find_files(opts)
"endfunction
"
"" 映射快捷键
"nnoremap <leader>ff :call MyCustomFinder()<CR>
let g:jedi#show_call_signatures = "0"

