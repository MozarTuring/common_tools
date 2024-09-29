vim.cmd [[set runtimepath^=$jwHomePath/zzzresources/software/nvim/vim_pack]]
vim.cmd [[set runtimepath+=$jwHomePath/zzzresources/software/nvim/vim_pack/after]]
vim.cmd [[let &packpath = &runtimepath]]

-- 设置 256 色支持
-- vim.o.termguicolors = true
vim.o.t_Co = 256

-- 基础设置
vim.o.compatible = false
vim.cmd [[filetype off]]


-- vim.fn.system({'curl', '-fLo', $jwHomePath/zzzresources/software/nvim/vim_pack/autoload/plug.vim, '-create-dirs', 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'})

vim.cmd [[
call plug#begin('$jwHomePath/zzzresources/software/nvim/vim_pack/bundle')
Plug 'https://github.com/pocco81/auto-save.nvim.git'
"979b6c82f60cfa80f4cf437d77446d0ded0addf0
Plug 'https://github.com/tpope/vim-fugitive.git'
"dac8e5c2d85926df92672bf2afb4fc48656d96c7
"Plug 'https://github.com/Yggdroot/indentLine.git'
"b96a75985736da969ac38b72a7716a8c57bdde98
Plug 'https://github.com/davidhalter/jedi-vim.git'
"9bd79ee41ac59a33f5890fa50b6d6a446fcc38c7
Plug 'https://github.com/preservim/nerdtree.git'
"f3a4d8eaa8ac10305e3d53851c976756ea9dc8e8
Plug 'Vigemus/iron.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'
"Plug 'gbprod/substitute.nvim', { 'on':[]}
"Plug 'https://github.com/svermeulen/vim-subversive.git'
call plug#end()
]]


-- 开启语法高亮
vim.o.syntax = "on"

-- 开启文件类型插件和缩进
vim.o.filetype = true
vim.o.plugin = true
vim.o.indent = true

-- 开启大小写不敏感的搜索
vim.o.ic = true

-- 开启高亮搜索
vim.o.hlsearch = true

-- 设置编码为 UTF-8
vim.o.encoding = "utf-8"

-- 设置文件编码
vim.o.fileencodings = "utf-8,ucs-bom,GB2312,big5"

-- 设置光标行
vim.o.cursorline = true

-- 开启自动缩进
vim.o.autoindent = true

-- 开启智能缩进
vim.o.smartindent = true

-- 设置滚动偏移
vim.o.scrolloff = 4

-- 显示匹配的括号
vim.o.showmatch = true

-- 关闭行号显示
vim.o.number = false

-- 设置 Python 文件类型特定的缩进和格式化
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    command = "set tabstop=4 softtabstop=4 shiftwidth=4 expandtab fileformat=unix",
})

-- 设置 Python 文件类型的代码折叠
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    command = "set foldmethod=indent foldlevel=99",
})

-- 设置背景色
vim.o.background = "light"


-- 设置 NERDTree 显示隐藏文件
vim.g.NERDTreeShowHidden = 1

-- 映射快捷键 ,t 来聚焦 NERDTree
vim.api.nvim_set_keymap('n', ',t', ':NERDTreeFocus<CR>', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('n', 'fp', ':lua print("aidasa")<CR>', { noremap = true, silent = true })

local jwview = function(inp)
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

-- iron also has a list of commands, see :h iron-commands for all available commands
-- vim.keymap.set('n', '<space>rs', '<cmd>IronRepl<cr>')
vim.keymap.set('n', '<space>rr', '<cmd>IronRestart<cr>')
-- vim.keymap.set('n', '<space>rf', '<cmd>IronFocus<cr>')
-- vim.keymap.set('n', '<space>rh', '<cmd>IronHide<cr>')


-- repl_open_cmd = "vertical botright 80 split"

-- -- But iron provides some utility functions to allow you to declare that dynamically,
-- -- based on editor size or custom logic, for example.

-- -- Vertical 50 columns split
-- -- Split has a metatable that allows you to set up the arguments in a "fluent" API
-- -- you can write as you would write a vim command.
-- -- It accepts:
-- --   - vertical
-- --   - leftabove/aboveleft
-- --   - rightbelow/belowright
-- --   - topleft
-- --   - botright
-- -- They'll return a metatable that allows you to set up the next argument
-- -- or call it with a size parameter
-- repl_open_cmd = view.split.vertical.botright(50)

-- -- If the supplied number is a fraction between 1 and 0,
-- -- it will be used as a proportion
-- repl_open_cmd = view.split.vertical.botright(0.61903398875)

-- -- The size parameter can be a number, a string or a function.
-- -- When it's a *number*, it will be the size in rows/columns
-- -- If it's a *string*, it requires a "%" sign at the end and is calculated
-- -- as a percentage of the editor size
-- -- If it's a *function*, it should return a number for the size of rows/columns

-- repl_open_cmd = view.split("40%")

-- -- You can supply custom logic
-- -- to determine the size of your
-- -- repl's window
-- repl_open_cmd = view.split.topleft(function()
--   if some_check then
--     return vim.o.lines * 0.4
--   end
--   return 20
-- end)

-- -- An optional set of options can be given to the split function if one
-- -- wants to configure the window behavior.
-- -- Note that, by default `winfixwidth` and `winfixheight` are set
-- -- to `true`. If you want to overwrite those values,
-- -- you need to specify the keys in the option map as the example below

-- repl_open_cmd = view.split("40%", {
--   winfixwidth = false,
--   winfixheight = false,
--   -- any window-local configuration can be used here
--   number = true
-- })

-- local function mjw()
--     print("Hello, World!")
-- end
-- 定义一个函数来启动指定 Python 解释器的 REPL
--global function mjw()
--  local abs_path = vim.api.nvim_call_function('GetAbsPath', {"b"})
--  print(abs_path)
--  require('iron').setup({
--    repl = {
--      cmd = { python_executable, '-i' },  -- 使用指定的 Python 解释器
--    },
--  })
--  require('iron').start()
--end

-- 映射一个快捷键来启动指定 Python 解释器的 REPL
-- vim.api.nvim_set_keymap('n', 'fz', ':lua mjw()<CR>', { noremap = true, silent = true })



local home_path = os.getenv('jwHomePath')
local actions = require("telescope.actions")
require('telescope').setup {
  defaults = {
    file_ignore_patterns = { '**/111mjw_tmp_jwm', '.git', '.hg', 'zzzresources' },  -- 忽略这些目录
    mappings = {
	    i = {
	    ["<c-j>"] = actions.move_selection_next,
	    ["<c-k>"] = actions.move_selection_previous,
            ["<esc>"] = actions.close
	    },
    }
    },
	pickers = {
        find_files = {
            -- 使用环境变量
            path_display = { "absolute" },
            cwd = home_path,
            hidden = true, -- 显示隐藏文件
        },
    },
}
local builtin = require('telescope.builtin')
vim.keymap.set('n', 'ff', builtin.find_files, { desc = 'Telescope find files' })
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
--vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.o.termguicolors = true

vim.cmd('source $jwHomePath/common_tools/init_nvim.vim')


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
--local stat = vim.loop.fs_stat(file_path)
--if stat then
--print("File:", file_path)
--print("Type:", stat.type)
--print("Size:", stat.size)
--print("Last modification time (seconds):", stat.mtime.sec)
--print("---")
--else
--print("Failed to retrieve file system information for:", file_path)
--end
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
        print("Content appended successfully.")
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
    local command = string.format("mkdir %s", inp_dir)

    -- Execute the command
    local success = os.execute(command)

    -- Check if the command was executed successfully
    if success == 0 then
        print("Directory created successfully.")
    else
        print("Failed to create directory.")
    end
end

function directory_exists(dir_path)
    local stat = vim.loop.fs_stat(dir_path)
    return stat and stat.type == 'directory'
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
--        local tmp = 'jwo=jwcl("' .. tmp_dir .. '")'
    local tmp = vim.fn.GetAbsPath("a")
    local abs_dir = tmp[2]
    local cur_name = tmp[3]
--    local current_time = os.date("%Y%m%d_%H%M%S")
--    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") .. "/" .. current_time
    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") 
    local tmp_path = tmp_dir .. '/' .. cur_name .. 'log.txt'
    local tmp_path2 = tmp_dir .. '/' .. cur_name .. 'log.txt.tmp'
    if not directory_exists(tmp_dir) then
        jw_mkdir(tmp_dir)
    end
    
    return tmp_path, tmp_path2
end

local function jw_center()
--    local last_line_number = vim.api.nvim_buf_line_count(0)
--
---- Get the window height
--    local window_height = vim.api.nvim_win_get_height(0)
--
--    -- Calculate the middle line number
--    local middle_line_number = math.ceil((window_height - 1) / 2)
--
--    -- Calculate the scroll offset to center the last line
--    local scroll_offset = last_line_number - middle_line_number
--
--    -- Set the window scroll offset to center the last line
--    vim.api.nvim_win_set_scroll(0, scroll_offset) -- no such fn
    vim.cmd('normal! zz') -- in the middle
--    vim.cmd('normal! zt') -- on top
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


function OpenLog()
    local tmp_path, tmp_path2 = get_log_path()
    local current_win_nr = vim.api.nvim_get_current_win()
    tmp_win = find_window_for_file(tmp_path)
    if tmp_win == nil then
        vim.cmd("botright vsplit " .. tmp_path)
        tmp_win = vim.api.nvim_get_current_win() -- if local tmp_win, it will be unknown outside if
--        print(type(tmp_win), tmp_win, "adfa")
    end
    vim.api.nvim_set_current_win(tmp_win)
    vim.cmd("edit")
    local last_line_number = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_cursor(0, {last_line_number, 0})
--    vim.api.nvim_set_current_win(tmp_win)
--    vim.api.nvim_feedkeys('G', "n", true)
    jw_center()
    vim.api.nvim_set_current_win(current_win_nr)
end
vim.api.nvim_set_keymap('n', 'fl', '<cmd>lua OpenLog()<CR>', { noremap = true, silent = true })


function Jwcl()
--    local abs_path = vim.api.nvim_call_function('GetAbsPath', {"b"})
    local tmp = vim.fn.GetAbsPath("a")
    local abs_dir = tmp[2]
    local cur_name = tmp[3]
    local current_time = os.date("%Y%m%d_%H%M%S")
    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") .. "/" .. current_time
    local tmp = 'jwo=jwcl("' .. tmp_dir .. '")'
    local current_win_nr = vim.api.nvim_get_current_win()
    iron.send(nil, tmp)
    vim.cmd("botright vsplit " .. tmp_dir .. '/log.txt')
    _G.myw = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(current_win_nr)
    vim.api.nvim_feedkeys('i' .. tmp, "n", true)

--    vim.fn.setreg('a', tmp)
    
--    local tmp = '"aP'
--    vim.api.nvim_feedkeys(tmp, "n", true)
--    iron.send_line()
--    vim.api.nvim_feedkeys("<Esc>", 'n', true)
--    vim.api.nvim_feedkeys('Ojwo="' .. tmp_dir .. '"', "n", true)
    --    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
--    vim.api.nvim_feedkeys("fl", 'n', true)
--    vim.fn.get_log_path('')
--    setup_auto_refresh(tmp_dir .. '/log.txt')
end
vim.api.nvim_set_keymap('n', 'fj', '<cmd>lua Jwcl()<CR>', { noremap = true, silent = true })


function PrintCurrentMode()
  local mode_info = vim.api.nvim_get_mode()
  local current_mode = mode_info.mode

  print("Current mode: " .. current_mode)
end
--vim.api.nvim_set_keymap('v', '<leader>u', '<cmd>lua PrintCurrentMode()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'mm', ':lua PrintCurrentMode()<CR>', {noremap = true})


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


local jw_send = function(inp_send, inp_line)
    local today = os.date("%Y-%m-%d")
    local current_time = os.date("%H:%M:%S")
    if inp_line == 1 then
        session_start = '\n\n**********' .. today .. '**********\n'
    else
        session_start = "\n"
    end
    local tmp_path, tmp_path2 = get_log_path(inp_send)
    local new_send = 'sys.stdout = open("' .. tmp_path .. '", "a") \n' .. inp_send .. '\nsys.stdout.close()'
    jw_append(session_start .. '[' .. current_time .. ']\n' .. inp_send .. '  [INPEND]\n', tmp_path)
    iron.send(nil, new_send)
    OpenLog()
--    local tmp_content = jwread(tmp_path2)
--    print(tmp_content)
--    vim.fn.input("p")
--    jw_append(tmp_path, "[OUT]: "..tmp_content)

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
vim.api.nvim_set_keymap('n', 'm', ":lua Jw_send_l()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap('i', '<M-l>', "<cmd>lua Jw_send_l()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap('i', '<S-Return>', "<cmd>lua Jw_send_l()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap('i', '<S-Return>', 'v:lua.Jw_send_l()', { expr = true })
--vim.api.nvim_set_keymap('i', '<c-l>', ":lua Jw_send_l()<CR>", { noremap = true, silent = true }) invalid

function Jw_send_v()
--    local mode_info = vim.api.nvim_get_mode()
--    print("Current mode: " .. mode_info.mode)
--    local mode = vim.api.nvim_get_mode().mode
--    print(mode)
    tmp_start = vim.fn.line("'<")
    tmp_end = vim.fn.line("'>")
    tmp_gap = tmp_end-tmp_start
    vim.api.nvim_feedkeys(tmp_gap .. 'j', 'n', true) 
--    print(tmp_gap)
--    vim.fn.input("p")
    local lines = vim.fn.getline(tmp_start, tmp_end)
    local tmp_send = table.concat(lines, "\n") 
    jw_send(tmp_send, tmp_start)
end
--vim.api.nvim_set_keymap('v', '<space>ll', '<cmd>lua Jwsend()<CR>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('v', 'm', ":lua Jw_send_v()<CR>", { noremap = true, silent = true })



--function Uw()
--print(vim.api.nvim_buf_get_name(0))
--this could return abs path
--end


--function InsertCurrentTime()
--  local current_time = os.date("%Y-%m-%d %H:%M:%S")
--  print(current_time)
--  vim.api.nvim_replace_termcodes(current_time, true, true, true)
--end

--vim.api.nvim_set_keymap('n', '<leader>t', '<cmd>lua InsertCurrentTime()<CR>', { noremap = true, silent = true })

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

