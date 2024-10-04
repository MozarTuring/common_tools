
" Below is my design

func! Comment() range
    let prefix = join([a:firstline,a:lastline],",")
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

