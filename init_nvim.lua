local function isWindows()
    local uname = vim.loop.os_uname()
    return uname.sysname == "Windows" or uname.sysname == "Windows_NT"
end
is_win = isWindows()


if is_win then
    jwHomePath = 'C:/Users/Mozar/BaiduSyncdisk'
else
    jwHomePath = '~'
end

local function directory_exists(dir_path)
    local stat = vim.loop.fs_stat(dir_path)
    return stat and stat.type == 'directory'
end

local function file_exists(path)
    local stat = vim.loop.fs_stat(path)
        if stat and stat.type == 'file' then
            return true
        else
            return false
    end
end

vim.cmd('set runtimepath^=' .. jwHomePath .. '/project/zzzresources/software/nvim/vim_pack')
vim.cmd('set runtimepath+=' .. jwHomePath .. '/project/zzzresources/software/nvim/vim_pack/after')
vim.cmd('let &packpath = &runtimepath')


-- 基础设置

vim.cmd[[
set t_Co=256

set nocompatible              " be iMproved, required

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

let python_highlight_all=1
au Filetype python set tabstop=4
au Filetype python set softtabstop=4
au Filetype python set shiftwidth=4
au Filetype python set expandtab
au Filetype python set fileformat=unix
autocmd Filetype python set foldmethod=indent
autocmd Filetype python set foldlevel=99

syntax enable

set background=light

let NERDTreeShowHidden=1
]]


local tmp_path = jwHomePath .. '/project/zzzresources/software/nvim/vim_pack/autoload/plug.vim'
if not file_exists(tmp_path) then
    vim.cmd('!curl -fLo ' .. tmp_path .. ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
end

local bundle_path = jwHomePath .. '/project/zzzresources/software/nvim/vim_pack/bundle'
vim.cmd('call plug#begin("' .. bundle_path .. '")')
vim.cmd [[
Plug 'https://github.com/pocco81/auto-save.nvim.git'
Plug 'https://github.com/preservim/nerdtree.git'
]]
if is_win then
    vim.cmd [[
        Plug 'Vigemus/iron.nvim'
        Plug 'https://github.com/davidhalter/jedi-vim.git'
        Plug 'https://github.com/tpope/vim-fugitive.git'
        Plug 'nvim-telescope/telescope.nvim'
        Plug 'nvim-lua/plenary.nvim'
        call plug#end()
]]


-- 设置 Python 文件类型特定的缩进和格式化
vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = "python",
    command = "setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab fileformat=unix",
})

-- 设置 Python 文件类型的代码折叠
vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = "python",
    command = "setlocal foldmethod=indent foldlevel=99",
})

local function jwview(inp)
    vim.cmd("tabnew")
    local winid = vim.api.nvim_get_current_win()
    return winid
end


local iron = require("iron.core")
local view = require('iron.view')

iron.setup {
  config = {
    -- Whether a repl should be discarded or not
    scratch_repl = true,
    -- Your repl definitions come here
    repl_definition = {
      sh = {
        -- Can be a table or a function that
        -- returns a table (see below)
        command = {"zsh"}
      },
      python = {
        command = { "python3" },  -- or { "ipython", "--no-autoindent" }
        format = require("iron.fts.common").bracketed_paste_python
      }
    },
    -- How the repl window will be displayed
    -- See below for more information
    -- repl_open_cmd = require('iron.view').bottom(40),
--    repl_open_cmd = view.split.vertical.botright(50),
--    repl_open_cmd = view.split.horizontal.below(0.3),
    repl_open_cmd = jwview,
  },
  -- Iron doesn't set keymaps by default anymore.
  -- You can set them here or manually add keymaps to the functions in iron.core
  keymaps = {
--    visual_send = "<space>ll",
--    send_line = "<space>ll",
    -- send_file = "<space>sf",
    -- send_motion = "<space>sc",
    -- send_paragraph = "<space>sp",
    -- send_until_cursor = "<space>su",
    -- send_mark = "<space>sm",
    -- mark_motion = "<space>mc",
    -- mark_visual = "<space>mc",
    -- remove_mark = "<space>md",
    -- cr = "<space>s<cr>",
    -- interrupt = "<space>s<space>",
    -- exit = "<space>sq",
    -- clear = "<space>cl",
  },
  -- If the highlight is on, you can change how it looks
  -- For the available options, check nvim_set_hl
  highlight = {
    italic = true
  },
  ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
}

local actions = require("telescope.actions")
local action_state = require('telescope.actions.state')

tmp_cwd = jwHomePath .. '/project'
require('telescope').setup {
  defaults = {
--    cwd = tmp_cwd,
--    hidden = true,
    relative = true,
    file_ignore_patterns = { '**/111mjw_tmp_jwm', '.git', '.hg', 'zzzresources' },  -- 忽略这些目录
    mappings = {
	    i = {
        ["<esc>"] = actions.close,
        ["<CR>"] = function(prompt_bufnr)
                    -- Get the current selection's file path
                    local selection = action_state.get_selected_entry(prompt_bufnr)
                    -- Close the Telescope picker
                    actions.close(prompt_bufnr)
                    -- Open the file in a new tab
                    if is_win then
                        vim.cmd('tabnew ' .. selection.value)
                    else
                    vim.cmd('tabnew ' .. tmp_cwd .. '/' .. selection.value)
                    end
                end
	    },
    }
    },
	pickers = {
        find_files = {
            cwd = tmp_cwd,
            hidden = true, -- 显示隐藏文件
            relative = true
        },
        buffers = {
            relative = true
        }
    },
}
local builtin = require('telescope.builtin')
--vim.keymap.set('n', 'ff', '<cmd> lua require("telescope.builtin").find_files()<CR>', { desc = 'Telescope find files' })
vim.keymap.set('n', 'ff', builtin.find_files, { desc = 'Telescope find files' })
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
--vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.opt.termguicolors = true


vim.cmd('source ' .. jwHomePath .. '/project/common_tools/init_nvim.vim')

local function setup_auto_refresh(file_path)
-- Create an augroup to contain the autocommands
vim.api.nvim_create_augroup("AutoRefresh", { clear = true })

-- Define an autocommand for the specific file
vim.api.nvim_create_autocmd("BufReadPost", {
group = "AutoRefresh",
pattern = file_path,
callback = function()
-- Check if the file has been modified externally
local stat = vim.loop.fs_stat(file_path)
if stat and stat.mtime.sec > vim.api.nvim_buf_get_mark(0, "<")[1] then
-- If modified, reload the buffer
local tmp = "edit " .. file_path
vim.cmd("edit " .. file_path)
end
end,
})
end

local function retrieve_file_info(file_path)
    local buf_nr = vim.fn.bufnr(file_path)
    local win_nr = vim.fn.win_getpos(buf_nr)[1]
    vim.api.nvim_set_current_win(win_nr)
    local last_win_nr = vim.fn.tabpagewinnr(vim.api.nvim_get_current_tabpage(), "$")
end

local function start_periodic_retrieval(file_path, interval)
-- Create a timer
local timer = vim.loop.new_timer()

-- Start the timer to retrieve file info periodically
timer:start(interval, interval, vim.schedule_wrap(function()
require("init").retrieve_file_info(file_path)
end))

return timer
end

local function read_source(source)
    if vim.fn.filereadable(source) == 1 then
        -- If the source is a file path, read its content
        local source_file_handle = io.open(source, "r")
        if source_file_handle then
            local content = source_file_handle:read("*a") -- Read the entire file content
            source_file_handle:close() -- Close the source file handle
            return content
        else
            error("Error: Unable to open the source file.")
        end
    else
        -- If the source is not a file path, treat it as text
        return source
    end
end

-- Function to append content to the destination file
local function append_content(content, destination_file_path)
    -- Open the destination file in append mode
    local destination_file_handle = io.open(destination_file_path, "a")
    if destination_file_handle then
        -- Append the content to the destination file
        destination_file_handle:write(content)
        destination_file_handle:close() -- Close the destination file handle
--        print("Content appended successfully.")
    else
        error("Error: Unable to open the destination file for appending.")
    end
end

-- Main function to append content from source to destination
local function jw_append(source, dst)
    local content = read_source(source)
    append_content(content, dst)
end


local jw_mkdir = function(inp_dir)
    local command = string.format("mkdir -p %s", inp_dir)

    -- Execute the command
    local success = os.execute(command)

    -- Check if the command was executed successfully
    if success == 0 then
--        print("Directory created successfully.")
    else
--        print("Failed to create directory.")
    end
end


local function find_window_for_file(file_path)
    local windows = vim.api.nvim_list_wins()
    for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
--        print(buf_name, file_path, win)
        if buf_name == file_path then
            return win
        end
    end
    return nil
end


local function get_log_path()
    local tmp = vim.fn.GetAbsPath("a")
    local abs_dir = tmp[2]
    local cur_name = tmp[3]
    local abs_path = abs_dir .. '/' .. cur_name
    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") .. '/' .. cur_name
    
    local tmp_path = tmp_dir .. '/log.txt'

    tmp_count = 1
    tmp_path2 = _G.tmp_dir2 .. '/' .. tmp_count .. '.txt'
    while file_exists(tmp_path2) do
        tmp_count = tmp_count + 1
        tmp_path2 = _G.tmp_dir2 .. '/' .. tmp_count .. '.txt'
    end
    
    return tmp_path, tmp_path2, tmp[1], tmp_dir
end

local function jw_center()
    vim.cmd('normal! zz') -- in the middle
end

local function get_last_lines()
    local num_lines = 15
    local last_line_number = vim.api.nvim_buf_line_count(0)
    local start_line_number = math.max(1, last_line_number - num_lines)
    local last_5_lines = vim.api.nvim_buf_get_lines(0, start_line_number - 1, last_line_number, false)
    local new_lines = {}
    for _, line in ipairs(last_5_lines) do
        if line ~= "" then
            table.insert(new_lines, "")
        end
    end
    vim.api.nvim_buf_set_lines(0, last_line_number, -1, false, new_lines)
end

local function open_cur(inp)
    local current_line = vim.api.nvim_get_current_line()
    local filename = current_line:match "^%s*(.-)%s*$" -- 去除前后空格

    if filename ~= nil and vim.loop.fs_stat(filename) then
        vim.cmd('botright split ' .. filename)
    else
        vim.api.nvim_set_current_win(inp)
    end
end


local function RefreshFile(buffer_name, current_win_nr)
    local bufnr = vim.fn.bufnr(buffer_name)

    -- Check if the buffer exists and is loaded
    if bufnr ~= -1 and vim.fn.buflisted(bufnr) == 1 then
        -- Execute checktime for the specific buffer
        vim.api.nvim_buf_call(bufnr, function()
            vim.cmd('checktime')
        end)
    else
--        print("refresh error")
    end
--    vim.api.nvim_set_current_win(current_win_nr)
end

-- Create a timer to refresh the file every 30 seconds
local timer = vim.loop.new_timer()


function OpenLog()
    local tmp_path = get_log_path()
    local current_win_nr = vim.api.nvim_get_current_win()
    tmp_win = find_window_for_file(tmp_path)
    if tmp_win == nil then
        vim.cmd("botright split " .. tmp_path)
        tmp_win = vim.api.nvim_get_current_win() -- if local tmp_win, it will be unknown outside if
    end
    vim.api.nvim_set_current_win(tmp_win)
    vim.cmd("edit")
    local last_line_number = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_cursor(0, {last_line_number, 0})
    jw_center()
    if _G.jwtimer == nil then
        timer:start(1000, 1000, vim.schedule_wrap(function()
                RefreshFile(tmp_path, current_win_nr)
            end))
        _G.jwtimer = "set"
    end
    open_cur(current_win_nr)
end




local jwread = function(source_file_path, destination_file_path)
    -- Open the source file and read its content
    local source_file_handle = io.open(source_file_path, "r")
    if source_file_handle then
        local source_content = source_file_handle:read("*a") -- Read the entire file content
        source_file_handle:close() -- Close the source file handle

        -- Open the destination file in append mode
        local destination_file_handle = io.open(destination_file_path, "a")
        if destination_file_handle then
            -- Append the source content to the destination file
            destination_file_handle:write(source_content)
            destination_file_handle:close() -- Close the destination file handle

            print("Content appended successfully.")
        else
            print("Error: Unable to open the destination file for appending.")
        end
    else
        print("Error: Unable to open the source file.")
    end
end

local function clear_file(inp)
    local file = io.open(inp, "w")
    if file then
        file:close() -- 关闭文件
    else
        print("Error: unable to open file")
    end
end


--local function del_log(inp)
--    os.remove(inp)
--end


local function jw_restart()
    local current_time = os.date("%Y%m%d_%H%M%S")
    local tmp = vim.fn.GetAbsPath("a")
    local abs_dir = tmp[2]
    local cur_name = tmp[3]
    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") .. '/' .. cur_name
    local tmp_path = tmp_dir .. '/log.txt'
    clear_file(tmp_path)
    _G.jwsession = tmp[1]
    _G.tmp_dir2 = tmp_dir .. '/log' .. current_time
    jw_mkdir(_G.tmp_dir2)
    if not directory_exists(tmp_dir) then
        jw_mkdir(tmp_dir)
    end
end

local jw_send = function(inp_send, inp_line)
--    local today = os.date("%Y-%m-%d")
--    session_start = '\n\n**********' .. today .. '**********\n'
--    print(_G.jwsession) it will be set to nil when restart nvim
    local tmp = vim.fn.GetAbsPath("a")
    if not string.match(tmp[1], "%.py$") then
        error("not python")
    end

    local err = ''
    local ou = ''
    local tmp_copy = ''
    if _G.jwsession == nil then
        jw_restart()
        tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
    elseif _G.jwsession ~= tmp[1] then
        jw_restart()
        tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
        iron.repl_restart()
    else
        tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
        err = 'sys.stderr = open("' .. tmp_path .. '", "a") \n'
        ou = 'sys.stdout = open("' .. tmp_path2 .. '", "w") \n'
        tmp_copy = '\n\nsys.stdout.close()\nsys.stderr.close()\njwcopy_file_content("' .. tmp_path2 .. '", "' .. tmp_path .. '")\n'
    end
    session_start = "\n"
    
    local new_send = err .. ou .. inp_send .. tmp_copy
    jw_append(session_start .. '\n' .. inp_send .. '  [INPEND]\n', tmp_path)
    iron.send(nil, new_send)
    OpenLog()
--    local tmp_content = jwread(tmp_path2)
end


function Jw_send_l()
--    local mode_info = vim.api.nvim_get_mode()
--    vim.api.nvim_echo({{"Current mode: " .. mode_info.mode}}, true)
--    vim.api.nvim_feedkeys("<Esc>", "i", true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
--    local current_line = vim.api.nvim_get_current_line()
    local tmp_send = vim.fn.getline(".")
    local cursor_position = vim.api.nvim_win_get_cursor(0)
    local current_line_number = cursor_position[1]
    jw_send(tmp_send, current_line_number)
--    if current_line:match("^%s*$") then
--        Jwcl()
--    elseif string.sub(current_line, 1, 3) == "jwp" then
--    elseif string.find(current_line, '=') then
--    else
--        current_line = 'jwp(' .. current_line .. ')'
--        vim.api.nvim_feedkeys('ddO' .. current_line, 'n', true) 
--    end
    

--    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
end
function Jw_send_v()
--    local mode_info = vim.api.nvim_get_mode()
--    print("Current mode: " .. mode_info.mode)
--    local mode = vim.api.nvim_get_mode().mode
--    print(mode)
    tmp_start = vim.fn.line("'<")
    tmp_end = vim.fn.line("'>")
    tmp_gap = tmp_end-tmp_start
    vim.api.nvim_feedkeys(tmp_gap .. 'j', 'n', true) 
    local lines = vim.fn.getline(tmp_start, tmp_end)
    local tmp_send = table.concat(lines, "\n") 
    jw_send(tmp_send, tmp_start)
end

function jw_iron_restart()
    jw_restart()
    iron.repl_restart()
end


local function mygg(args)
    vim.api.nvim_feedkeys(args .. "gg", "n", true)
    vim.api.nvim_feedkeys("^", "n", true)
end
vim.keymap.set('n', 'gg', function()
    mygg(vim.v.count)
end, { silent = true, noremap = true })

local function myG()
    vim.api.nvim_feedkeys("G", "n", true)
    vim.api.nvim_feedkeys("$", "n", true)
end
vim.keymap.set('v', 'G', function()
    myG()
end, { silent = true, noremap = true })

--vim.opt.mouse = 'a'
vim.opt.mouse = ''

function is_in_inp_dir(current_file, inp_dir)
--  print(current_file, current_file:sub(1, #inp_dir), inp_dir)
  return current_file:sub(1, #inp_dir) == inp_dir
end


function CopyFilePathToClipboard()
    local file_path = vim.fn.expand('%:p')  -- Gets the full path of the current file
    vim.fn.setreg('+', file_path)           -- Copies the path to the clipboard register (+)
    print('Copied to clipboard: ' .. file_path)  -- Optional: prints a confirmation message
end

function myWriteFile()
--    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
--            local bufname = vim.api.nvim_buf_get_name(buf)
--            vim.api.nvim_buf_command(buf, 'silent w')
--        end
--    end
    local file_path = vim.fn.expand('%:p')  -- Gets the full path of the current file
    -- Check the directory and execute specific shell commands
    if is_in_inp_dir(file_path, "/home/maojingwei/project/common_tools") then
        vim.cmd('silent w')
        -- Execute the command using jwclone
        tmp = "jwclone " .. file_path .. " 42"
        vim.cmd('!' .. tmp)
--        os.execute("jwclone " .. file_path .. " 42")
    end
end
function OpenOrSwitchToFile(filename)
    local bfound = false
    -- Check all windows to see if the file is already open
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:find(filename) then
            -- File is open, switch to the window
            vim.api.nvim_set_current_win(win)
            bfound = true
            break
        end
    end

    if not bfound then
        -- File is not open, open it in a new buffer
        vim.cmd('tabnew ' .. filename)
    end
end


vim.api.nvim_create_user_command('Jwtabnew', function(args)
    OpenOrSwitchToFile(args.args)
end, { nargs = 1, complete = 'file' })

--function jwtabnewfunc(filename)
--    local bool_found = false
--    -- Check all windows to see if the file is already open
--    for _, win in ipairs(vim.api.nvim_list_wins()) do
--        local buf = vim.api.nvim_win_get_buf(win)
--        local buf_name = vim.api.nvim_buf_get_name(buf)
--        if buf_name:find(filename) then
--            -- File is open, switch to the window
--            vim.api.nvim_set_current_win(win)
--            found = true
--            break
--        end
--    end
--
--    if not bool_found then
--        -- File is not open, open it in a new buffer
--        vim.cmd('edit ' .. filename)
--    end
--end
--
--vim.api.nvim_create_user_command('jwtabnew', function(args)
--    jwtabnewfunc(args.args)
--end, { nargs = 1, complete = 'file' })
vim.cmd('set title')

-- Function to copy visually selected lines using start and end line numbers
function copy_visual_lines()
    -- Get the start and end positions of the visual selection
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    local tmp_num = end_line - start_line

    -- Get lines from the buffer
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    -- Convert the table of lines into a single string with newline characters
    local text = table.concat(lines, "\n")

    -- Copy the text to the unnamed register
    vim.fn.setreg('*', start_line .. ',' .. tmp_num .. "|" .. text, "c")
end

function copy_normal_lines()
    local start_line = vim.fn.line(".")
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)

    -- Convert the table of lines into a single string with newline characters
    local text = table.concat(lines, "\n")

    -- Copy the text to the unnamed register
    vim.fn.setreg('*', start_line .. ',' .. 0 .. "|" .. text, "c")
end



function goto_or_add_line(line_num)
    local total_lines = vim.api.nvim_buf_line_count(0) -- Get the total number of lines in the current buffer
    if line_num > total_lines then
        -- If the line number is greater than the total, add new lines
        local lines_to_add = line_num - total_lines
        local new_lines = {}
        for i = 1, lines_to_add do
            table.insert(new_lines, "") -- Add empty lines
        end
        vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, new_lines) -- Add new lines at the end of the buffer
    end
    vim.api.nvim_win_set_cursor(0, {line_num, 0}) -- Move cursor to the specified line
end

function CursorPosition()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return "Line " .. row .. ":" .. "Col " .. col
end
--vim.opt.statusline = "%f %h%m%r%=%{v:lua.CursorPosition()} %l/%L %c"
vim.opt.statusline = "%l/%L %f %h%m%r"
vim.opt.endofline = true
vim.o.clipboard = 'unnamedplus'
vim.cmd('let g:jedi#show_call_signatures = "0"')
vim.cmd('let g:jedi#use_tabs_not_buffers = 1')
vim.cmd('let g:jedi#popup_on_dot = 0')

function createDir(path)
    if not directory_exists(path) then
    os.execute("mkdir -p " .. path)
end
end

function MyRefreshFile()
    -- 执行命令 "e"，通常用于编辑文件，但在这里可能只是刷新当前文件
    vim.cmd("e")

    -- 执行普通模式命令 "G"，跳转到文件末尾
    vim.cmd("normal G")
end

function Clswap()
    -- 执行 shell 命令来删除交换文件
    vim.cmd("!rm " .. jwHomePath .. "/.local/state/nvim/swap/*")
end

vim.cmd('let NERDTreeChDirMode=2')


--keymaps
vim.api.nvim_set_keymap('n', ',f', ':NERDTreeFind<CR>', { noremap = true })

-- 保存并退出
vim.api.nvim_set_keymap('n', ';q', ':q<CR>', { noremap = true, silent = true })

-- 保存所有文件并退出
vim.api.nvim_set_keymap('n', ';a', ':qall<CR>', { noremap = true, silent = true })

-- 执行自定义函数刷新文件
vim.api.nvim_set_keymap('n', ';e', ':lua MyRefreshFile()<CR>', { noremap = true, silent = true })

-- 编译并运行 GCC 程序
vim.api.nvim_set_keymap('n', '<2-LeftMouse>', ':call CompileRunGcc(\'r\')<CR>', { noremap = true, silent = true })

-- 使用 Jedi 跳转到定义
vim.api.nvim_set_keymap('n', 'gj', ':call jedi#goto()<CR>', { noremap = true, silent = true })

-- 重映射 gt 到 gT
vim.api.nvim_set_keymap('n', 'gt', 'gT', { noremap = true, silent = true })

-- 重映射 gy 到 gt
vim.api.nvim_set_keymap('n', 'gy', 'gt', { noremap = true, silent = true })

-- 设置键映射，使用 Clswap 函数
vim.api.nvim_set_keymap('n', 'cls', ':lua Clswap()<CR>', { noremap = true })


vim.api.nvim_set_keymap('n', 'fl', '<cmd>lua OpenLog()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'm', ":lua Jw_send_l()<CR>", { noremap = true, silent = true })

--vim.api.nvim_set_keymap('v', '<space>ll', '<cmd>lua Jwsend()<CR>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('v', 'm', ":lua Jw_send_v()<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<space>rr', '<cmd>lua jw_iron_restart()<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', 'yp', '<cmd>lua CopyFilePathToClipboard()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', ';w', '<cmd>lua myWriteFile()<CR>', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', 's', '<Nop>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<c-o>', '<Nop>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<space>', '<Nop>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<M-o>', '<Nop>', {noremap = true, silent = true})


vim.api.nvim_set_keymap('v', 'sy', ':lua copy_visual_lines()<CR>', {noremap = true, silent = true}) -- here <cmd> not work in windows

vim.api.nvim_set_keymap('n', 'sy', ':lua copy_normal_lines()<CR>', {noremap = true, silent = true})

