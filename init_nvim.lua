--for windows
--mklink C:\Users\Mozar\AppData\Local\nvim\init.lua C:\Users\Mozar\BaiduSyncdisk\project\common_tools\init_nvim.lua

local vim_version = vim.version()
--print(vim_version) it's not a string, although can print
local function isWindows()
	local uname = vim.loop.os_uname()
	return uname.sysname == "Windows" or uname.sysname == "Windows_NT"
end
--is_win = isWindows()

if is_win then
	jwHomePath = "C:/Users/Mozar/BaiduSyncdisk/project"
else
	jwHomePath = "~"
end

local function directory_exists(dir_path)
	local stat = vim.loop.fs_stat(dir_path)
	return stat and stat.type == "directory"
end

local function file_exists(path)
	local stat = vim.loop.fs_stat(path)
	if stat and stat.type == "file" then
		return true
	else
		return false
	end
end

-- 基础设置

vim.cmd([[
set t_Co=256

set nocompatible              " be iMproved, required

syntax on
filetype plugin indent on
set ic
set hlsearch
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,GB2312,big5
set fileformat=unix
set cursorline
set autoindent
set smartindent
set scrolloff=4
set showmatch

autocmd Filetype * set tabstop=4|set softtabstop=4|set shiftwidth=4|set expandtab|set foldmethod=indent|set foldlevel=99

"set background=light
let NERDTreeShowHidden=1
let python_highlight_all=1
"hi Normal guibg=NONE ctermbg=NONE
]])
-- vim.opt.termguicolors = true

--vim.opt.mouse = 'a'
vim.opt.mouse = "" -- don't activate vim mouse, then system mouse will be activated on vim and then can use mouse to select text and copy to system clipboard

-- local tmp_path = jwHomePath .. '/nvim/vim_pack/autoload/plug.vim'
-- tmp = file_exists(tmp_path) -- will be false if using ~ rather than abs
-- if not tmp then
--     vim.cmd('!curl -fLo ' .. tmp_path .. ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
-- end

local function python_package_exists(pkg)
	return os.execute("pip show " .. pkg .. " >/dev/null 2>&1") == 0
end

if vim_version.major == 0 and vim_version.minor == 9 and vim_version.patch == 1 then
	print("for remote")
	local bundle_path = jwHomePath .. "/jwSoftware/vim_pack/bundle"
	vim.cmd("set runtimepath^=" .. bundle_path .. "/../")
	vim.cmd("set runtimepath+=" .. jwHomePath .. "/../after")
	vim.cmd("let &packpath = &runtimepath")
	print(vim.inspect(vim.opt.runtimepath:get()))

	vim.cmd('call plug#begin("' .. bundle_path .. '")')
	vim.cmd(
		[[ Plug 'https://github.com/pocco81/auto-save.nvim.git', {'commit':'979b6c82f60cfa80f4cf437d77446d0ded0addf0'} ]]
	)
	vim.cmd(
		[[ Plug 'https://github.com/preservim/nerdtree.git', {'commit':'690d061b591525890f1471c6675bcb5bdc8cdff9'} ]]
	)
	vim.cmd([[ Plug 'Vigemus/iron.nvim', {'commit':'0e07ace465edff6c4ed6db9f3b7bf919c40aeffb'} ]])
	vim.cmd([[ Plug 'nvim-lua/plenary.nvim' , {'commit': 'b9fd5226c2f76c951fc8ed5923d85e4de065e509'}]])
	vim.cmd([[ Plug 'nvim-telescope/telescope.nvim', {'commit':'78857db9e8d819d3'} ]])

	vim.cmd("call plug#end()")
	-- 设置 Python 文件类型特定的缩进和格式化
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = "python",
		command = "setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab fileformat=unix",
	})

	-- 设置 Python 文件类型的代码折叠
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = "python",
		command = "setlocal foldmethod=indent foldlevel=99",
	})
end

if vim_version.major == 0 and vim_version.minor == 11 and vim_version.patch == 5 then
	print("mac neovim")

	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		local lazyrepo = "https://github.com/folke/lazy.nvim.git"
		local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
		if vim.v.shell_error ~= 0 then
			vim.api.nvim_echo({
				{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
				{ out, "WarningMsg" },
				{ "\nPress any key to exit..." },
			}, true, {})
			vim.fn.getchar()
			os.exit(1)
		end
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup({
		spec = {
			-- add LazyVim and import its plugins
			{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
			-- import/override with your plugins
			{ import = "plugins" },
			{ "pocco81/auto-save.nvim" },
			{ "Vigemus/iron.nvim" },
			{ "tpope/vim-fugitive" },
			{ "NeogitOrg/neogit" },
			{ "iamcco/markdown-preview.nvim" },
			{ "HakonHarnes/img-clip.nvim" },
			{ "lervag/vimtex" },
			{ "numToStr/Comment.nvim" },
		},
		defaults = {
			-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
			-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
			lazy = false,
			-- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
			-- have outdated releases, which may break your Neovim install.
			version = false, -- always use the latest git commit
			-- version = "*", -- try installing the latest stable version for plugins that support semver
		},
		install = { colorscheme = { "tokyonight", "habamax" } },
		checker = {
			enabled = true, -- check for plugin updates periodically
			notify = false, -- notify on update
		}, -- automatically check for plugin updates
		performance = {
			rtp = {
				-- disable some rtp plugins
				disabled_plugins = {
					"gzip",
					-- "matchit",
					-- "matchparen",
					-- "netrwPlugin",
					"tarPlugin",
					"tohtml",
					"tutor",
					"zipPlugin",
				},
			},
		},
	})
end

local function jwview(inp)
	vim.cmd("tabnew")
	local winid = vim.api.nvim_get_current_win()
	return winid
end

local iron = require("iron.core")
local view = require("iron.view")

iron.setup({
	config = {
		-- Whether a repl should be discarded or not
		scratch_repl = true,
		-- Your repl definitions come here
		repl_definition = {
			sh = {
				-- Can be a table or a function that
				-- returns a table (see below)
				command = { "zsh" },
			},
			python = {
				command = { "python3" }, -- or { "ipython", "--no-autoindent" }
				format = require("iron.fts.common").bracketed_paste_python,
			},
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
		italic = true,
	},
	ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
})

-- Defer telescope setup until it's loaded by lazy.nvim
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyLoad",
	callback = function(event)
		if event.data ~= "telescope.nvim" then return end
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		require("telescope").setup({
			defaults = {
				hidden = true,
				no_ignore = true,
				no_ignore_parent = true,
				file_ignore_patterns = { "__pycache__/", ".git", ".hg", "zzzresources" },
				mappings = {
					i = {
						["<CR>"] = function(prompt_bufnr)
							local selection = action_state.get_selected_entry(prompt_bufnr)
							actions.close(prompt_bufnr)
							local tmp_value = string.sub(selection.value, 1)
							abs_path = tmp_value
							vim.cmd("Jwtabnew " .. abs_path)
						end,
					},
				},
			},
		})
	end,
})
--local builtin = require('telescope.builtin')
vim.keymap.set(
	"n",
	"ff",
	'<cmd> lua require("telescope.builtin").find_files({hidden=true})<CR>',
	{ desc = "Telescope find files" }
)
vim.keymap.set(
	"n",
	"fg",
	'<cmd> lua require("telescope.builtin").live_grep({hidden=true})<CR>',
	{ desc = "Telescope find files" }
)
-- vim.keymap.set('n', 'ff', builtin.find_files, { desc = 'Telescope find files' })
-- --vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
-- --vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
-- --vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

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

local function jw_mkdir(inp_dir)
	if not directory_exists(inp_dir) then
		vim.cmd("!mkdir -p " .. inp_dir)
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

local function jw_center()
	vim.cmd("normal! zz") -- in the middle
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

local function open_cur()
	local current_line = vim.api.nvim_get_current_line()
	local filename = current_line:match("^%s*(.-)%s*$") -- 去除前后空格

	local filename = string.sub(filename, 4)
	if filename ~= nil and vim.loop.fs_stat(filename) then
		vim.cmd("tabnew " .. filename)
		return "open"
	end
end

local function RefreshFile(buffer_name)
	local bufnr = vim.fn.bufnr(buffer_name)

	-- Check if the buffer exists and is loaded
	if bufnr ~= -1 and vim.fn.buflisted(bufnr) == 1 then
		-- Execute checktime for the specific buffer
		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("checktime")
			--            local last_line_number = vim.api.nvim_buf_line_count(0)
			--            vim.api.nvim_win_set_cursor(0, {last_line_number, 0})
			--            jw_center()
		end)
	else
		--        print("refresh error")
	end
	--    vim.api.nvim_set_current_win(current_win_nr)
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

local function get_log_path(inp)
	local current_time = os.date("%Y%m%d_%H%M%S")
	local tmp = vim.fn.GetAbsPath("a")
	local abs_dir = tmp[2]
	local cur_name = tmp[3]
	--    local abs_path = abs_dir .. '/' .. cur_name
	tmp_dir = abs_dir .. "/jwoutput/" .. cur_name .. "/logs"

	tmp_count = 1
	if _G.tmp_dir2 ~= nil then
		tmp_path2 = _G.tmp_dir2 .. "/" .. tmp_count .. ".txt"
		while file_exists(tmp_path2) do
			tmp_count = tmp_count + 1
			tmp_path2 = _G.tmp_dir2 .. "/" .. tmp_count .. ".txt"
		end
	else
		tmp_path2 = nil
	end

	if inp == "restart" then
		_G.jwsession = tmp[1]
		_G.tmp_dir2 = tmp_dir .. "/" .. current_time
		jw_mkdir(_G.tmp_dir2)
		jw_mkdir(tmp_dir)
		return current_time
	end

	local tmp_path = tmp_dir .. "/log.txt"
	return tmp_path, tmp_path2, tmp[1], tmp_dir
end

local timer = vim.loop.new_timer()
function OpenLog()
	tmp = vim.api.nvim_buf_get_name(0)
	if string.sub(tmp, -2) == "xt" then
		open_cur()
		return
	end
	local tmp_path = get_log_path()
	local current_win_nr = vim.api.nvim_get_current_win()
	tmp_win = find_window_for_file(tmp_path)
	if tmp_win == nil then
		vim.cmd("botright 32split " .. tmp_path)
		tmp_win = vim.api.nvim_get_current_win() -- if local tmp_win, it will be unknown outside if
	end
	vim.api.nvim_set_current_win(tmp_win)
	vim.cmd("edit")
	local last_line_number = vim.api.nvim_buf_line_count(0)
	vim.api.nvim_win_set_cursor(0, { last_line_number, 0 })
	jw_center()
	if _G.jwtimer ~= tmp_path then
		timer:start(
			1000,
			1000,
			vim.schedule_wrap(function()
				RefreshFile(tmp_path)
			end)
		)
		_G.jwtimer = tmp_path
	end
	open_cur()
end

--local function jw_restart()
--    local current_time = os.date("%Y%m%d_%H%M%S")
--    local tmp = vim.fn.GetAbsPath("a")
--    local abs_dir = tmp[2]
--    local cur_name = tmp[3]
--    local tmp_dir = abs_dir .. "/jwo" ..  os.getenv("jwPlatform") .. '/' .. cur_name
--    local tmp_path = tmp_dir .. '/log.txt'
----    clear_file(tmp_path)
--    _G.jwsession = tmp[1]
--    _G.tmp_dir2 = tmp_dir .. '/logs/' .. current_time
--    jw_mkdir(_G.tmp_dir2)
--    jw_mkdir(tmp_dir)
--    return current_time
--end

local jw_send = function(inp_send, inp_line)
	--    local today = os.date("%Y-%m-%d")
	--    session_start = '\n\n**********' .. today .. '**********\n'
	--    print(_G.jwsession) it will be set to nil when restart nvim
	local tmp = vim.fn.GetAbsPath("a")
	if not string.match(tmp[1], "%.py$") then
		error("not python")
	end

	local init = ""
	local startstamp = "jwstarttime=time.time()\n"
	local timecost = "jwtimecost=time.time()-jwstarttime\n"
	session_start = "\n" -- because most cases execute this
	if _G.jwsession == nil then
		tmp_time = get_log_path("restart")
		session_start = "\n************ " .. tmp_time .. " ************\n"
		tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
		init = 'jwo="' .. tmp_dir .. '/.."\nfrom common_tools.jwu2 import *\n'
		err = 'sys.stderr = open("' .. tmp_path2 .. '", "a") \n'
		ou = 'sys.stdout = open("' .. tmp_path2 .. '", "w") \n'
		tmp_copy = '\n\njwcopy_file_content("'
			.. tmp_path2
			.. '", "'
			.. tmp_path
			.. '")\nsys.stdout.close()\nsys.stderr.close()\n'
	elseif _G.jwsession ~= tmp[1] then
		tmp_time = get_log_path("restart")
		--        tmp_time = jw_restart()
		session_start = "\n************ " .. tmp_time .. " ************\n"
		tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
		iron.repl_restart()
		init = 'jwo="' .. tmp_dir .. '/.."\nfrom common_tools.jwu2 import *\n'
		err = 'sys.stderr = open("' .. tmp_path2 .. '", "a") \n'
		ou = 'sys.stdout = open("' .. tmp_path2 .. '", "w") \n'
		tmp_copy = '\n\njwcopy_file_content("'
			.. tmp_path2
			.. '", "'
			.. tmp_path
			.. '")\nsys.stdout.close()\nsys.stderr.close()\n'
	else
		tmp_path, tmp_path2, abs_path, tmp_dir = get_log_path()
		err = 'sys.stderr = open("' .. tmp_path2 .. '", "a") \n'
		ou = 'sys.stdout = open("' .. tmp_path2 .. '", "w") \n'
		tmp_copy = '\n\njwcopy_file_content("'
			.. tmp_path2
			.. '", "'
			.. tmp_path
			.. '")\nsys.stdout.close()\nsys.stderr.close()\n'
	end

	inp_send = inp_send:gsub("^%s%s%s%s", "")
	local new_send = init .. err .. ou .. startstamp .. inp_send .. tmp_copy .. timecost
	jw_append(session_start .. "\n[I] " .. inp_send .. "\n", tmp_path)
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
	tmp_gap = tmp_end - tmp_start
	vim.api.nvim_feedkeys(tmp_gap .. "j", "n", true)
	local lines = vim.fn.getline(tmp_start, tmp_end)
	local tmp_send = table.concat(lines, "\n")
	jw_send(tmp_send, tmp_start)
end

function jw_iron_restart()
	_G.jwsession = nil
	iron.repl_restart()
end

local function mygg(args)
	vim.api.nvim_feedkeys(args .. "gg", "n", true)
	vim.api.nvim_feedkeys("^", "n", true)
end
vim.keymap.set("n", "gg", function()
	mygg(vim.v.count)
end, { silent = true, noremap = true })

local function myG()
	vim.api.nvim_feedkeys("G", "n", true)
	vim.api.nvim_feedkeys("$", "n", true)
end
vim.keymap.set("v", "G", function()
	myG()
end, { silent = true, noremap = true })

function is_in_inp_dir(current_file, inp_dir)
	--  print(current_file, current_file:sub(1, #inp_dir), inp_dir)
	return current_file:sub(1, #inp_dir) == inp_dir
end

function CopyFilePathToClipboard()
	local file_path = vim.fn.expand("%:p") -- Gets the full path of the current file
	vim.fn.setreg("+", file_path) -- Copies the path to the clipboard register (+)
	print("Copied to clipboard: " .. file_path) -- Optional: prints a confirmation message
end

function myWriteFile()
	--    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	--        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
	--            local bufname = vim.api.nvim_buf_get_name(buf)
	--            vim.api.nvim_buf_command(buf, 'silent w')
	--        end
	--    end
	local file_path = vim.fn.expand("%:p") -- Gets the full path of the current file
	-- Check the directory and execute specific shell commands
	vim.cmd("silent w")
	if is_in_inp_dir(file_path, "/home/maojingwei/project/common_tools") then
		vim.cmd("silent w")
		-- Execute the command using jwclone
		--        tmp = "jwclone " .. file_path .. " 42"
		--        vim.cmd('!' .. tmp)
		--        os.execute("jwclone " .. file_path .. " 42")
	end
end

--vim.api.nvim_create_autocmd("VimEnter", {
--  callback = function()
--    local cwd = vim.loop.cwd()
--    local target = vim.fn.expand("~/project")
--
--    if cwd ~= target then
--      vim.cmd("cd " .. target)
--    end
--  end
--})

function goto_or_open_terminal()
	local api = vim.api

	-- 1) If any window in any tab is already showing a terminal buffer, jump there.
	for _, tab in ipairs(api.nvim_list_tabpages()) do
		for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
			local buf = api.nvim_win_get_buf(win)
			if vim.bo[buf].buftype == "terminal" then
				api.nvim_set_current_tabpage(tab)
				api.nvim_set_current_win(win)
				return
			end
		end
	end

	-- 2) Otherwise, if there exists a hidden terminal buffer, show it in a split.
	for _, buf in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
			vim.cmd("botright split")
			api.nvim_win_set_buf(0, buf)
			vim.cmd("startinsert") -- optional: enter terminal input
			return
		end
	end

	-- 3) Otherwise, create a new terminal.
	vim.cmd("botright split | terminal")
	vim.cmd("startinsert") -- optional
end

function OpenOrSwitchToFile(filename)
	local cwd = vim.loop.cwd() -- absolute path, no ~
	local project_dir = vim.fn.expand("~/project")

	if cwd ~= project_dir then
		print("Not in ~/project")
	end
	local bfound = false
	-- Check all windows to see if the file is already open
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local buf_name = vim.api.nvim_buf_get_name(buf)
		--        print(buf_name, filename)
		--        print(type(buf_name), type(filename))
		--        local tmp = buf_name:find(filename)   this is pattern find not string find
		if filename:sub(1, 1) == "." then
			filename = filename:sub(3)
		end
		local tmp = buf_name:find(filename, 1, true)
		--        print(tmp)
		if tmp then
			vim.api.nvim_set_current_win(win)
			bfound = true
			break
		end
	end

	if not bfound then
		local dir = filename:match("^(.*)/")
		jw_mkdir(dir)
		vim.cmd("tabnew " .. filename)
	end
end

vim.api.nvim_create_user_command("Jwtabnew", function(args)
	OpenOrSwitchToFile(args.args)
end, { nargs = 1, complete = "file" })

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
vim.cmd("set title")

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
	vim.fn.setreg("*", start_line .. "," .. tmp_num .. "|" .. text, "c")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	vim.api.nvim_feedkeys(end_line .. "ggj", "n", true)
end

function copy_normal_lines()
	local start_line = vim.fn.line(".")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)

	-- Convert the table of lines into a single string with newline characters
	local text = table.concat(lines, "\n")

	-- Copy the text to the unnamed register
	vim.fn.setreg("*", start_line .. "," .. 0 .. "|" .. text, "c")
	vim.api.nvim_feedkeys("j", "n", true)
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
	vim.api.nvim_win_set_cursor(0, { line_num, 0 }) -- Move cursor to the specified line
end

-- function CursorPosition()
--     local row, col = unpack(vim.api.nvim_win_get_cursor(0))
--     return "Line " .. row .. ":" .. "Col " .. col
-- end
--vim.opt.statusline = "%f %h%m%r%=%{v:lua.CursorPosition()} %l/%L %c"
vim.opt.statusline = "%l/%L %f %h%m%r"
vim.opt.endofline = true
-- vim.cmd('let g:jedi#show_call_signatures = "0"')
-- vim.cmd('let g:jedi#use_tabs_not_buffers = 1')
-- vim.cmd('let g:jedi#popup_on_dot = 0')

function MyRefreshFile()
	-- 执行命令 "e"，通常用于编辑文件，但在这里可能只是刷新当前文件
	vim.cmd("e")

	-- 执行普通模式命令 "G"，跳转到文件末尾
	vim.cmd("normal G")
end

function Clswap()
	-- 执行 shell 命令来删除交换文件
	vim.cmd("!rm " .. "~/.local/state/nvim/swap/*")
end

vim.cmd("let NERDTreeChDirMode=2")

vim.api.nvim_set_keymap("n", "s", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "cc", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "I", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "t", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<c-o>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<space>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<M-o>", "<Nop>", { noremap = true, silent = true })

--keymaps
vim.api.nvim_set_keymap("n", ",f", ":NERDTreeFind<CR>", { noremap = true })

-- 保存并退出
vim.api.nvim_set_keymap("n", ";q", ":q<CR>", { noremap = true, silent = true })

-- 保存所有文件并退出
vim.api.nvim_set_keymap("n", ";a", ":qall<CR>", { noremap = true, silent = true })

-- 执行自定义函数刷新文件
vim.api.nvim_set_keymap("n", ";e", ":lua MyRefreshFile()<CR>", { noremap = true, silent = true })

-- 编译并运行 GCC 程序
vim.api.nvim_set_keymap("n", "<2-LeftMouse>", ":call CompileRunGcc('r')<CR>", { noremap = true, silent = true })

-- 使用 Jedi 跳转到定义
vim.api.nvim_set_keymap("n", "gj", ":call jedi#goto()<CR>", { noremap = true, silent = true })

-- 重映射 gt 到 gT
vim.api.nvim_set_keymap("n", "gt", "gT", { noremap = true, silent = true })

-- 重映射 gy 到 gt
vim.api.nvim_set_keymap("n", "gy", "gt", { noremap = true, silent = true })

-- 设置键映射，使用 Clswap 函数
vim.api.nvim_set_keymap("n", "cls", ":lua Clswap()<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "fl", "<cmd>lua OpenLog()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', 'm', ":lua Jw_send_l()<CR>", { noremap = true, silent = true })

--vim.api.nvim_set_keymap('v', '<space>ll', '<cmd>lua Jwsend()<CR>', { noremap = true, silent = true})
--vim.api.nvim_set_keymap('v', 'm', ":lua Jw_send_v()<CR>", { noremap = true, silent = true })

--vim.api.nvim_set_keymap('n', 'ee', '<cmd>lua jw_iron_restart()<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "cp", "<cmd>lua CopyFilePathToClipboard()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "cp", "<cmd>lua CopyFilePathToClipboard()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ";w", "<cmd>lua myWriteFile()<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("v", "sy", ":lua copy_visual_lines()<CR>", { noremap = true, silent = true }) -- here <cmd> not work in windows

vim.api.nvim_set_keymap("n", "sy", ":lua copy_normal_lines()<CR>", { noremap = true, silent = true })

vim.cmd("source ~/project/common_tools/init_nvim.vim")
vim.opt.clipboard = "unnamedplus"

if vim_version.major == 0 and vim_version.minor == 11 and vim_version.patch == 5 then
	print("mac neovim")
	--    if not python_package_exists('jedi') then
	--        print('install jedi')
	--        os.execute('pip install jedi')
	--    end
	--    if not python_package_exists('pynvim') then
	--        print('install pynvim')
	--        os.execute('pip install pynvim')
	--    end

	-- Open preview when entering Normal mode
	local function cmd_exists(cmd)
		return vim.fn.exists(":" .. cmd) == 2
	end

	--vim.cmd([[ function! mkdp#autocmd#clear_buf() abort
	--  silent! augroup MKDP_REFRESH_INIT
	--    autocmd! * <buffer>
	--  augroup END
	--endfunction
	--]])

	--require('glow').setup({
	--  -- your override config
	--})
	-- Open Glow immediately on markdown open
	--
	vim.cmd([[
function! OpenMarkdownPreview(url)
  call system(
        \ 'open -na "Google Chrome" --args ' .
        \ '--profile-directory="markdownpreview" ' .
        \ shellescape(a:url) . ' >/dev/null 2>&1 &'
        \ )
endfunction

let g:mkdp_browserfunc = 'OpenMarkdownPreview'
]])

	-- Tell markdown-preview.nvim to use our browser opener
	--vim.g.mkdp_browserfunc = "MkdpBrowserStay"

	-- Define the function in Vimscript (simplest + reliable)
	--vim.cmd([[
	--function! MkdpBrowserStay(url) abort
	--  " macOS: open in background (do NOT steal focus)
	--  call jobstart(['open', '-g', a:url], {'detach': v:true})
	--endfunction
	--]])

	vim.cmd([[
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 0
]])

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			vim.keymap.set("n", "m", "<cmd>MarkdownPreviewToggle<CR>", { buffer = true, desc = "Markdown Preview" })
		end,
	})

	--vim.api.nvim_create_autocmd("BufEnter", {
	--  pattern = "*.md",
	--  callback = function()
	--    if vim.fn.mode() == "n" then
	--      pcall(vim.cmd, "MarkdownPreview")
	--    end
	--  end,
	--})

	-- Close preview when editing
	--vim.api.nvim_create_autocmd("InsertEnter", {
	--  pattern = "*.md",
	--  callback = function()
	--    pcall(vim.cmd, "")
	--  end,
	--})
	--
	---- Re-open preview when back to normal mode
	--vim.api.nvim_create_autocmd("InsertLeave", {
	--  pattern = "*.md",
	--  callback = function()
	--    pcall(vim.cmd, "MarkdownPreview")
	--  end,
	--})
	--

	require("img-clip").setup({
		default = {
			dir_path = "jw_md_imgs",
			relative_to_current_file = true,
			prompt_for_file_name = false,
		},
	})

	--vim.keymap.set({ "n", "i" }, "<D-v>", function()
	--  if vim.bo.filetype ~= "markdown" then
	--    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
	--    return
	--  end
	--
	--  -- check if clipboard contains image (macOS)
	--  local has_image = vim.fn.system("pngpaste -b >/dev/null 2>&1; echo $?")
	--  if has_image:match("0") then
	--    vim.cmd("PasteImage")
	--  else
	--    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
	--  end
	--end, { desc = "Smart Cmd+V" })

	vim.keymap.set({ "n" }, "<leader>v", "<cmd>PasteImage<CR>", { desc = "Smart Cmd+V" })

	require("mason").setup()

	-- 1) nvim-cmp
	vim.opt.completeopt = { "menu", "menuone", "noselect" }

	local cmp = require("cmp")

	cmp.setup({
		mapping = cmp.mapping.preset.insert({
			["<C-Space>"] = cmp.mapping.complete(), -- manually trigger
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<Tab>"] = cmp.mapping.select_next_item(),
			["<S-Tab>"] = cmp.mapping.select_prev_item(),
		}),
		sources = cmp.config.sources({
			{ name = "nvim_lsp" },
			{ name = "buffer" },
			{ name = "path" },
		}),
	})

	-- 2) Hook LSP capabilities into cmp
	local capabilities = require("cmp_nvim_lsp").default_capabilities()

	-- 3) Mason + LSPConfig
	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = { "pyright", "lua_ls" },
	})

	vim.lsp.config("pyright", {
		capabilities = capabilities,
	})

	vim.lsp.config("lua_ls", {
		capabilities = capabilities,
		settings = {
			Lua = { diagnostics = { globals = { "vim" } } },
		},
	})

	vim.diagnostic.config({
		signs = false,
	})

	vim.lsp.enable("pyright")
	vim.lsp.enable("lua_ls")

	vim.keymap.set("n", "gj", vim.lsp.buf.definition, { noremap = true, silent = true })

	require("Comment").setup({
		operator_mapping = "?",
		mappings = {
			basic = false,
			extra = false,
		},
	})

	--local api = require("Comment.api")
	--
	--vim.keymap.set("n", "?", api.toggle.linewise.current)
	--vim.keymap.set("v", "?", function()
	--  api.toggle.linewise(vim.fn.visualmode())
	--end)

	require("gitsigns").setup({
		signs = {
			add = { text = "┃" },
			change = { text = "┃" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged = {
			add = { text = "┃" },
			change = { text = "┃" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = true,
		signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
		numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
		linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
		word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
		watch_gitdir = {
			follow_files = true,
		},
		auto_attach = true,
		attach_to_untracked = false,
		current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 1000,
			ignore_whitespace = false,
			virt_text_priority = 100,
			use_focus = true,
		},
		current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil, -- Use default
		max_file_length = 40000, -- Disable if file is longer than this (in lines)
		preview_config = {
			-- Options passed to nvim_open_win
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
	})

	vim.keymap.set("n", "<leader>h", require("gitsigns").preview_hunk, { desc = "Preview git hunk" })

	vim.opt.number = true
	vim.o.clipboard = "unnamedplus"
end
