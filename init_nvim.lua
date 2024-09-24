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
Plug 'https://github.com/vim-airline/vim-airline.git', { 'on':[]}
"d9f42cb46710e31962a9609939ddfeb0685dd779
Plug 'https://github.com/pocco81/auto-save.nvim.git'
"979b6c82f60cfa80f4cf437d77446d0ded0addf0
Plug 'https://github.com/mattn/emmet-vim.git'
"def5d57a1ae5afb1b96ebe83c4652d1c03640f4d
Plug 'https://github.com/tpope/vim-fugitive.git'
"dac8e5c2d85926df92672bf2afb4fc48656d96c7
"Plug 'https://github.com/Yggdroot/indentLine.git'
"b96a75985736da969ac38b72a7716a8c57bdde98
Plug 'https://github.com/davidhalter/jedi-vim.git'
"9bd79ee41ac59a33f5890fa50b6d6a446fcc38c7
Plug 'https://github.com/preservim/nerdtree.git'
"f3a4d8eaa8ac10305e3d53851c976756ea9dc8e8
Plug 'bfredl/nvim-ipy', { 'on':[]}
Plug 'https://github.com/ivanov/vim-ipython.git', { 'on':[]}
Plug 'Vigemus/iron.nvim'
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


vim.cmd('source $jwHomePath/common_tools/init_nvim.vim')


local iron = require("iron.core")
local view = require("iron.view")

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
--        command = function()
--          local abs_path = vim.api.nvim_call_function('GetAbsPath', {"b"})
--          print(abs_path)
--          local current_dir = vim.fn.fnamemodify(current_file_path, ':h')
--          return { current_dir .. "/aaaMjw_TMP/condaenv/bin/python" }
--        end,
        format = require("iron.fts.common").bracketed_paste_python
      }
    },
    -- How the repl window will be displayed
    -- See below for more information
    -- repl_open_cmd = require('iron.view').bottom(40),
    repl_open_cmd = view.split.vertical.botright(50),
  },
  -- Iron doesn't set keymaps by default anymore.
  -- You can set them here or manually add keymaps to the functions in iron.core
  keymaps = {
    send_motion = "<space>sc",
    visual_send = "<space>sc",
    send_file = "<space>sf",
    send_line = "<space>sl",
    send_paragraph = "<space>sp",
    send_until_cursor = "<space>su",
    send_mark = "<space>sm",
    mark_motion = "<space>mc",
    mark_visual = "<space>mc",
    remove_mark = "<space>md",
    cr = "<space>s<cr>",
    interrupt = "<space>s<space>",
    exit = "<space>sq",
    clear = "<space>cl",
  },
  -- If the highlight is on, you can change how it looks
  -- For the available options, check nvim_set_hl
  highlight = {
    italic = true
  },
  ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
}

-- -- iron also has a list of commands, see :h iron-commands for all available commands
-- vim.keymap.set('n', '<space>rs', '<cmd>IronRepl<cr>')
-- vim.keymap.set('n', '<space>rr', '<cmd>IronRestart<cr>')
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
