--for windows
--mklink C:\Users\Mozar\AppData\Local\nvim\init.lua C:\Users\Mozar\BaiduSyncdisk\project\common_tools\init_nvim.lua

-- Disable netrw early, before any plugin loads (prevents duplicate explorer with neo-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- (moved after lazy.setup) vim.g.autoformat = false

local vim_version = vim.version()
--print(vim_version) it's not a string, although can print
local function isWindows()
	local uname = vim.loop.os_uname()
	return uname.sysname == "Windows" or uname.sysname == "Windows_NT"
end
is_win = isWindows()

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

-- local tmp_path = jwHomePath .. '/nvim/vim_pack/autoload/plug.vim'
-- tmp = file_exists(tmp_path) -- will be false if using ~ rather than abs
-- if not tmp then
--     vim.cmd('!curl -fLo ' .. tmp_path .. ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
-- end

local function python_package_exists(pkg)
	return os.execute("pip show " .. pkg .. " >/dev/null 2>&1") == 0
end

-- macneovim
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
		{ "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { autoformat = false, colorscheme = "vscode" } },
		-- import/override with your plugins
		{ import = "plugins" },
		-- Disable LazyVim's gy LSP keymap so we can use it for buffer cycling
		{
			"neovim/nvim-lspconfig",
			opts = function(_, opts)
				local keys = require("lazyvim.plugins.lsp.keymaps").get()
				keys[#keys + 1] = { "gy", false }
				opts.servers = opts.servers or {}
				opts.servers.pyright = opts.servers.pyright or {}
				opts.servers.pyright.settings = {
					python = {
						analysis = {
							diagnosticSeverityOverrides = {
								reportPossiblyUnboundVariable = "none",
								reportMissingImports = "none",
								reportMissingModuleSource = "none",
							},
						},
					},
				}
			end,
		},
		-- Always show the tab bar, even with one buffer
		{
			"akinsho/bufferline.nvim",
			opts = {
				options = {
					always_show_bufferline = true,
				},
			},
		},
		-- Show total lines in statusline (lualine), no time, no line:col
		{
			"nvim-lualine/lualine.nvim",
			opts = function(_, opts)
				-- Remove line:column (location) from the right side
				opts.sections.lualine_y = {}
				-- Replace lualine_z with only line/total (removes default time)
				opts.sections.lualine_z = {
					{
						function()
							return vim.fn.line(".") .. "/" .. vim.fn.line("$")
						end,
					},
				}
			end,
		},
		-- Customize blink.cmp
		{
			"saghen/blink.cmp",
			opts = function(_, opts)
				-- Show hidden files in path completion
				opts.sources = opts.sources or {}
				opts.sources.providers = opts.sources.providers or {}
				opts.sources.providers.path = opts.sources.providers.path or {}
				opts.sources.providers.path.opts = opts.sources.providers.path.opts or {}
				opts.sources.providers.path.opts.show_hidden_files_by_default = true

				-- Insert mode: Tab/S-Tab to navigate suggestions, Enter to confirm
				-- preselect=false ensures no item is auto-selected, must Tab first
				opts.completion = opts.completion or {}
				opts.completion.list = opts.completion.list or {}
				opts.completion.list.selection = { preselect = false, auto_insert = false }
				opts.keymap = opts.keymap or {}
				opts.keymap["<Tab>"] = { "select_next", "snippet_forward", "fallback" }
				opts.keymap["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" }
				opts.keymap["<CR>"] = { "accept", "fallback" }

				-- Disable cmdline completion entirely
				opts.cmdline = opts.cmdline or {}
				opts.cmdline.enabled = false
			end,
		},
		-- Disable noice.nvim to use built-in messages/cmdline
		{ "folke/noice.nvim", enabled = false },
		-- Disable neo-tree to avoid duplicate explorer with snacks.explorer
		{ "nvim-neo-tree/neo-tree.nvim", enabled = false },
		-- Configure snacks.explorer to show hidden/dot files, disable git icons
		{
			"folke/snacks.nvim",
			opts = function(_, opts)
				opts.notifier = opts.notifier or {}
				opts.notifier.timeout = 3

				opts.explorer = opts.explorer or {}
				opts.explorer.replace_netrw = false

				opts.picker = opts.picker or {}
				opts.picker.sources = opts.picker.sources or {}

				opts.picker.sources.files = opts.picker.sources.files or {}
				opts.picker.sources.files.win = opts.picker.sources.files.win or {}
				opts.picker.sources.files.win.input = opts.picker.sources.files.win.input or {}
				opts.picker.sources.files.win.input.keys = opts.picker.sources.files.win.input.keys or {}
				opts.picker.sources.files.win.input.keys["y"] = function()
					local pickers = Snacks.picker.get({ source = "files" })
					if #pickers > 0 then
						local item = pickers[1]:current()
						if item and item.file then
							vim.fn.setreg("+", item.file)
							vim.notify("Copied: " .. item.file)
						end
					end
				end

				opts.picker.sources.explorer = opts.picker.sources.explorer or {}
				local exp = opts.picker.sources.explorer
				exp.hidden = true
				exp.ignored = true
				exp.git_status = false
				exp.git_untracked = false
				exp.diagnostics = false
				exp.auto_close = true
				exp.jump = { close = true }
				exp.matcher = { fuzzy = false }
				exp.win = exp.win or {}
				exp.win.list = exp.win.list or {}
				exp.win.list.keys = exp.win.list.keys or {}
				local keys = exp.win.list.keys

				keys["y"] = {
					function(self)
						vim.defer_fn(function()
							local c = vim.fn.getcharstr()
							local pickers = Snacks.picker.get({ source = "explorer" })
							if #pickers == 0 then return end
							local item = pickers[1]:current()
							if not item or not item.file then return end
							if c == "y" then
								local name = vim.fn.fnamemodify(item.file, ":t")
								vim.fn.setreg("+", name)
								vim.notify("Copied name: " .. name)
							elseif c == "b" then
								local abs_path = vim.fn.fnamemodify(item.file, ":p")
								vim.fn.setreg("+", abs_path)
								vim.notify("Copied path: " .. abs_path)
							end
						end, 0)
					end,
					desc = "yy=copy name, yb=copy abs path",
				}

				keys["c"] = {
					function(self)
						local pickers = Snacks.picker.get({ source = "explorer" })
						if #pickers == 0 then return end
						local picker = pickers[1]
						local item = picker:current()
						if not item or not item.file then return end
						local sel = vim.tbl_map(Snacks.picker.util.path, picker:selected())
						if #sel > 0 then
							local dir = picker:dir()
							Snacks.picker.util.copy(sel, dir)
							picker.list:set_selected()
							picker:find()
							return
						end
						local fname = vim.fn.fnamemodify(item.file, ":t")
						local cwd = vim.loop.cwd()
						Snacks.input({
							prompt = "Copy " .. fname .. " to (relative to cwd)",
							completion = "file",
						}, function(value)
							if not value or value:find("^%s*$") then return end
							local uv = vim.uv or vim.loop
							local to
							if value:sub(1, 1) == "/" or value:sub(1, 1) == "~" then
								to = vim.fs.normalize(vim.fn.expand(value))
							else
								to = vim.fs.normalize(cwd .. "/" .. value)
							end
							local stat = uv.fs_stat(to)
							if stat and stat.type == "directory" then
								to = to .. "/" .. fname
							end
							if uv.fs_stat(to) then
								Snacks.notify.warn("File already exists:\n- `" .. to .. "`")
								return
							end
							local to_dir = vim.fs.dirname(to)
							if not uv.fs_stat(to_dir) then
								vim.fn.mkdir(to_dir, "p")
							end
							Snacks.picker.util.copy_path(item.file, to)
							picker:find()
						end)
					end,
					desc = "Copy file to destination",
				}

			keys["<cr>"] = {
				function()
					local pickers = Snacks.picker.get({ source = "explorer" })
					if #pickers == 0 then return end
					local picker = pickers[1]
					local item = picker:current()
					if not item or not item.file then return end
					if vim.fn.isdirectory(item.file) == 1 then
						picker:action("confirm")
						return
					end
					local file = item.file
					picker:close()
					local origin_buf = vim.api.nvim_get_current_buf()
					vim.cmd("edit " .. vim.fn.fnameescape(file))
					vim.schedule(function()
						local ok, bl = pcall(require, "bufferline")
						if not ok then return end
						local elems = bl.get_elements().elements
						local origin_pos = nil
						for i, e in ipairs(elems) do
							if e.id == origin_buf then
								origin_pos = i
								break
							end
						end
						if origin_pos then
							bl.move_to(origin_pos + 1)
						end
					end)
				end,
				desc = "Open file to the right in bufferline",
			}

			keys["p"] = "explorer_close"
			keys["r"] = "explorer_update"
			end,
		},
		{
			"stevearc/conform.nvim",
			event = { "BufReadPre" },
			cmd = { "ConformInfo" },
			opts = {
				format_on_save = false,
				formatters_by_ft = {
					python = { "black" },
					lua = { "stylua" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					tex = { "latexindent" },
				},
			},
		},
		{
			"pocco81/auto-save.nvim",
			opts = {
				execution_message = {
					message = "",
				},
		condition = function(buf)
			if not vim.api.nvim_buf_is_valid(buf) then
				return false
			end
			local bufname = vim.api.nvim_buf_get_name(buf)
			if bufname ~= "" and vim.fn.filereadable(bufname) == 0 then
				return false
			end
			local ext = vim.fn.expand("%:e")
			if ext == "tex" then
				return false
			end
			return true
		end,
			},
		},
		{ "Vigemus/iron.nvim" },
		{ "tpope/vim-fugitive" },
		{ "sindrets/diffview.nvim" },
		{
			"NeogitOrg/neogit",
			dependencies = { "sindrets/diffview.nvim" },
			opts = {
				integrations = { diffview = true },
				commit_view = { kind = "tab" },
			},
			keys = {
				{
					"<leader>gg",
					function()
						local path = vim.fn.expand("%:p:h")
						if path == "" then
							path = vim.loop.cwd()
						end
						local git_dir = vim.fs.find(".git", { upward = true, path = path })[1]
						local cwd = git_dir and vim.fn.fnamemodify(git_dir, ":h") or vim.loop.cwd()
						require("neogit").open({ cwd = cwd })
					end,
					desc = "Neogit (closest repo)",
				},
			},
		},
		{ "iamcco/markdown-preview.nvim", build = "cd app && npx --yes yarn install" },
	-- Enable wrap in all Neogit buffers
	{
		"NeogitOrg/neogit",
		init = function()
			vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
				callback = function()
					local ft = vim.bo.filetype or ""
					local name = vim.api.nvim_buf_get_name(0)
					if ft:match("^Neogit") or ft:match("^neogit") or name:match("Neogit") then
						vim.wo.wrap = true
					end
				end,
			})
		end,
	},
		{ "HakonHarnes/img-clip.nvim" },
		{
			"lervag/vimtex",
			init = function()
				vim.g.vimtex_view_method = "skim"
				vim.g.vimtex_view_skim_sync = 1 -- forward sync (tex -> pdf)
				vim.g.vimtex_view_skim_activate = 1 -- bring Skim to front on VimtexView
				vim.g.vimtex_compiler_method = "latexmk"
				vim.g.vimtex_compiler_latexmk = {
					aux_dir = "latex_compilation",
					out_dir = "",
					options = {
						"-synctex=1", -- enable synctex for inverse sync (pdf -> tex)
						"-interaction=nonstopmode",
						"-cd", -- change to file's directory before compiling
					},
				}

			-- Open Skim and forward-sync after every successful compile
			vim.api.nvim_create_autocmd("User", {
				pattern = "VimtexEventCompileSuccess",
				callback = function()
					vim.cmd("VimtexView")

					local tex_file = vim.fn.expand("%:p")
					local tex_dir = vim.fn.fnamemodify(tex_file, ":h")
					local base_name = vim.fn.fnamemodify(tex_file, ":t:r")
					local synctex = tex_dir .. "/" .. base_name .. ".synctex.gz"
					if vim.fn.filereadable(synctex) == 1 then
						local dest = tex_dir .. "/latex_compilation"
						vim.fn.mkdir(dest, "p")
						os.rename(synctex, dest .. "/" .. base_name .. ".synctex.gz")
					end

					-- Clean up stale pdflatex<PID>.fls files left by crashed compiles
					local handle = io.popen('ls "' .. tex_dir .. '"/pdflatex*.fls 2>/dev/null')
					if handle then
						for f in handle:lines() do
							os.remove(f)
						end
						handle:close()
					end

					vim.defer_fn(function()
						vim.cmd("echo ''")
					end, 2000)
				end,
			})

			-- Close Skim when quitting Neovim
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function()
					vim.fn.system({ "osascript", "-e", 'tell application "Skim" to quit' })
				end,
			})
			end,
		},
		{
			"Mofiqul/vscode.nvim",
			lazy = false,
			priority = 1000,
			opts = {
				style = "light",
				transparent = false,
			},
			config = function(_, opts)
				require("vscode").setup(opts)
				vim.cmd.colorscheme("vscode")
			end,
		},
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
	install = { colorscheme = { "vscode", "tokyonight", "habamax" } },
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
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

-- Disable LazyVim auto-format on save (must be after lazy.setup so it overrides LazyVim defaults)
vim.g.autoformat = false

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

-- Use snacks.picker (replaces telescope in modern LazyVim)
vim.keymap.set("n", "ff", function()
	Snacks.picker.files({
		hidden = true,
		ignored = true,
		exclude = { "__pycache__/", ".git", ".hg", "zzzresources" },
	})
end, { desc = "Find files" })
vim.keymap.set("n", "fg", function()
	Snacks.picker.grep({
		hidden = true,
		ignored = true,
		exclude = { "__pycache__/", ".git", ".hg", "zzzresources" },
		args = { "--fixed-strings" },
	})
end, { desc = "Live grep (literal)" })
vim.keymap.set("n", "fG", function()
	Snacks.picker.grep({
		hidden = true,
		ignored = true,
		exclude = { "__pycache__/", ".git", ".hg", "zzzresources" },
	})
end, { desc = "Live grep (regex)" })

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

function is_in_inp_dir(current_file, inp_dir)
	--  print(current_file, current_file:sub(1, #inp_dir), inp_dir)
	return current_file:sub(1, #inp_dir) == inp_dir
end

function CopyFilePathToClipboard()
	local file_path = vim.fn.expand("%:p") -- Gets the full path of the current file
	vim.fn.setreg("+", file_path) -- Copies the path to the clipboard register (+)
	-- print("Copied to clipboard: " .. file_path) -- Optional: prints a confirmation message
end

function CopyRelativePathToClipboard()
	local file_path = vim.fn.expand("%:.") -- Gets the relative path of the current file
	vim.fn.setreg("+", file_path) -- Copies the path to the clipboard register (+)
	-- print("Copied to clipboard: " .. file_path)
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
		local bufnr = vim.fn.bufadd(filename)
		vim.bo[bufnr].buflisted = true
		vim.cmd("buffer " .. bufnr)
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

vim.api.nvim_set_keymap("n", "w", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "s", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "cc", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "I", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "A", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "B", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "C", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "D", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "E", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "F", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "H", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "J", "<C-f>", { noremap = true, silent = true, desc = "Page down" })
vim.api.nvim_set_keymap("n", "K", "<C-b>", { noremap = true, silent = true, desc = "Page up" })
vim.api.nvim_set_keymap("n", "L", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "M", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "Q", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "R", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "S", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "T", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "U", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "W", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "X", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "Y", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "Z", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "t", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<c-o>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<space>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<M-o>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "r", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-r>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-g>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-f>", "<Nop>", { noremap = true, silent = true })

--keymaps
-- NERDTree mapping only for older nvim (0.9.1); overridden to Neotree in 0.11.5 block
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

-- 设置键映射，使用 Clswap 函数
vim.api.nvim_set_keymap("n", "cls", ":lua Clswap()<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "fl", "<cmd>lua OpenLog()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n', 'm', ":lua Jw_send_l()<CR>", { noremap = true, silent = true })

--vim.api.nvim_set_keymap('v', '<space>ll', '<cmd>lua Jwsend()<CR>', { noremap = true, silent = true})
--vim.api.nvim_set_keymap('v', 'm', ":lua Jw_send_v()<CR>", { noremap = true, silent = true })

--vim.api.nvim_set_keymap('n', 'ee', '<cmd>lua jw_iron_restart()<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "yb", "<cmd>lua CopyFilePathToClipboard()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ";w", "<cmd>lua myWriteFile()<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("v", "sy", ":lua copy_visual_lines()<CR>", { noremap = true, silent = true }) -- here <cmd> not work in windows

vim.api.nvim_set_keymap("n", "sy", ":lua copy_normal_lines()<CR>", { noremap = true, silent = true })
vim.cmd("source ~/project/common_tools/init_nvim.vim")
vim.opt.clipboard = "unnamedplus"
-- macneovim
vim.keymap.set("n", ",f", function()
	local ok, tree = pcall(require, "snacks.explorer.tree")
	if ok and not tree._jw_mtime_patched then
		tree._jw_mtime_patched = true
		local mt = getmetatable(tree)
		local uv = vim.uv or vim.loop
		mt.walk = function(self, node, fn, wopts)
			local abort = fn(node)
			if abort ~= nil then
				return abort
			end
			local children = vim.tbl_values(node.children)
			table.sort(children, function(a, b)
				if a.dir ~= b.dir then
					return a.dir
				end
				local sa = uv.fs_stat(a.path)
				local sb = uv.fs_stat(b.path)
				local ma = sa and sa.mtime and sa.mtime.sec or 0
				local mb = sb and sb.mtime and sb.mtime.sec or 0
				return ma > mb
			end)
			for c, child in ipairs(children) do
				child.last = c == #children
				abort = false
				if child.dir and (child.open or (wopts and wopts.all)) then
					abort = self:walk(child, fn, wopts)
				else
					abort = fn(child)
				end
				if abort then
					return true
				end
			end
			return false
		end
	end
	Snacks.explorer()
end, { noremap = true, desc = "Open file explorer" })


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

local grip_port = 6419
local grip_bin = "/Users/maojingwei/go/bin/go-grip"
local grip_root = nil

local function grip_running()
	return os.execute("curl -s -o /dev/null http://localhost:" .. grip_port) == 0
end

local function find_grip_root(path)
	local dir = vim.fn.fnamemodify(path, ":p:h")
	local prev = nil
	while dir ~= prev do
		if vim.fn.filereadable(dir .. "/README.md") == 1 or vim.fn.isdirectory(dir .. "/.git") == 1 then
			return dir
		end
		prev = dir
		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return vim.fn.fnamemodify(path, ":p:h")
end

local function start_grip(root)
	if grip_running() and grip_root == root then
		return
	end
	os.execute("pkill -f 'go-grip' 2>/dev/null")
	vim.wait(500, function() return false end)
	grip_root = root
	local cmd = grip_bin
		.. " -b=false"
		.. " -p " .. grip_port
		.. " " .. vim.fn.shellescape(root)
	vim.fn.jobstart(cmd, { detach = true })
	local ok = vim.wait(5000, grip_running, 200)
	if not ok then
		vim.notify("go-grip failed to start on " .. root, vim.log.levels.ERROR)
	end
end

local function open_in_grip()
	local file = vim.fn.expand("%:p")
	local root = find_grip_root(file)

	start_grip(root)

	-- go-grip serves from the parent of the path it receives,
	-- so the URL includes root's basename as a prefix.
	local serve_root = vim.fn.fnamemodify(root, ":h")
	local rel = file:sub(#serve_root + 2)
	local url = "http://localhost:" .. grip_port .. "/" .. rel
	local app = vim.fn.system(
		[[osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true']]
	):gsub("%s+$", "")
	vim.fn.system(
		'open -a "Safari" '
			.. vim.fn.shellescape(url)
			.. " >/dev/null 2>&1 &"
	)
	vim.defer_fn(function()
		vim.fn.system([[osascript -e 'tell application "]] .. app .. [[" to activate']])
	end, 600)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.spell = false
		vim.keymap.set("n", "m", open_in_grip, { buffer = true, desc = "Grip Preview" })
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


vim.keymap.set({ "n" }, "<leader>v", "<cmd>PasteImage<CR>", { desc = "Smart Cmd+V" })

require("mason").setup()

-- 1) nvim-cmp
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- local cmp = require("cmp")
--
-- cmp.setup({
-- 	mapping = cmp.mapping.preset.insert({
-- 		["<C-Space>"] = cmp.mapping.complete(), -- manually trigger
-- 		["<CR>"] = cmp.mapping.confirm({ select = true }),
-- 		["<Tab>"] = cmp.mapping.select_next_item(),
-- 		["<S-Tab>"] = cmp.mapping.select_prev_item(),
-- 	}),
-- 	sources = cmp.config.sources({
-- 		{ name = "nvim_lsp" },
-- 		{ name = "buffer" },
-- 		{ name = "path" },
-- 	}),
-- })

-- 2) Hook LSP capabilities into cmp
-- local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- 3) Mason + LSPConfig
-- require("mason").setup()
-- require("mason-lspconfig").setup({
-- 	ensure_installed = { "pyright", "lua_ls" },
-- })

vim.lsp.config("pyright", {
	capabilities = capabilities,
	settings = {
		python = {
			analysis = {
				diagnosticSeverityOverrides = {
					reportPossiblyUnboundVariable = "none",
					reportMissingImports = "none",
					reportMissingModuleSource = "none",
				},
			},
		},
	},
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

vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { strikethrough = false })
vim.api.nvim_set_hl(0, "@markup.strikethrough", { strikethrough = false })
vim.api.nvim_set_hl(0, "@markup.strikethrough.markdown_inline", { strikethrough = false })

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { strikethrough = false })
		vim.api.nvim_set_hl(0, "@markup.strikethrough", { strikethrough = false })
		vim.api.nvim_set_hl(0, "@markup.strikethrough.markdown_inline", { strikethrough = false })
	end,
})

-- Filter out noisy pyright diagnostics
local jw_suppress = {
	"is possibly unbound",
	"Expression value is unused",
	"Expected indented block",
}
do
	local orig = vim.lsp.handlers["textDocument/publishDiagnostics"]
	vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
		local filtered = {}
		for _, d in ipairs(result.diagnostics or {}) do
			local dominated = false
			for _, pattern in ipairs(jw_suppress) do
				if d.message and d.message:match(pattern) then
					dominated = true
					break
				end
			end
			if not dominated then
				table.insert(filtered, d)
			end
		end
		result.diagnostics = filtered
		return orig(err, result, ctx, config)
	end
end

-- Disable LSP formatting for all servers
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end
		-- Force gy/gt buffer cycling after all LSP keymaps are set
		local buf = args.buf
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.keymap.set("n", "gy", "<cmd>BufferLineCycleNext<CR>", { buffer = buf, noremap = true, silent = true })
				vim.keymap.set("n", "gt", "<cmd>BufferLineCyclePrev<CR>", { buffer = buf, noremap = true, silent = true })
				vim.keymap.set("n", "K", "<C-b>", { buffer = buf, noremap = true, silent = true, desc = "Page up" })
			end
		end, 500)
	end,
})

-- Keep fugitive :Gedit buffers alive when they lose focus
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "fugitive://*",
	callback = function()
		vim.bo.bufhidden = "hide"
	end,
})

vim.lsp.enable("pyright")
vim.lsp.enable("lua_ls")

vim.keymap.set("n", "gj", vim.lsp.buf.definition, { noremap = true, silent = true })

-- require("Comment").setup({
-- 	operator_mapping = "?",
-- 	mappings = {
-- 		basic = false,
-- 		extra = false,
-- 	},
-- })

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

-- Cmd+Z to undo in normal and insert mode
vim.keymap.set("n", "<D-z>", "u", { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set("i", "<D-z>", "<C-o>u", { noremap = true, silent = true, desc = "Undo" })

vim.opt.number = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.spell = false
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.conceallevel = 0 -- Show all markup syntax (don't hide image links, etc.)
-- 重映射 gt/gy: use BufferLine commands since LazyVim uses buffers as "tabs"
vim.defer_fn(function()
	vim.keymap.set("x", "V", function()
		if vim.fn.mode() == "\22" then
			return "<Ignore>"
		end
		return "V"
	end, { expr = true, noremap = true, silent = true, desc = "Disable V in visual block mode" })
	vim.keymap.set("x", "G", function()
		vim.cmd("normal! G$")
	end, { silent = true, desc = "Go to end of file + end of line" })
	-- After yank in visual mode, move cursor to end of selection
	vim.keymap.set("x", "y", "ygv<Esc>", { noremap = true, silent = true, desc = "Yank and go to end" })
	-- Remap gt/gy for buffer cycling (override LazyVim's gy = Goto Type Definition)
	vim.keymap.set("n", "gt", "<cmd>BufferLineCyclePrev<CR>", { noremap = true, silent = true, desc = "Previous buffer" })
	vim.keymap.set("n", "gy", "<cmd>BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
	vim.keymap.set(
		"v",
		"<C-s>",
		":call MyReplace()<CR>",
		{ noremap = true, silent = true, desc = "Search and replace selection" }
	)
	vim.keymap.set(
		"n",
		"<C-s>",
		":call MyReplaceNormal()<CR>",
		{ noremap = true, silent = true, desc = "Search and replace (prompt both)" }
	)
	-- Disable F after flash.nvim has loaded (flash overrides f/F/t/T)
	vim.keymap.set("n", "F", "<Nop>", { noremap = true, silent = true })
	-- ; prefixed keymaps (must be deferred, flash.nvim overrides ; otherwise)
	vim.keymap.set("n", ";q", function()
		if vim.bo.buftype == "terminal" then
			vim.cmd("bd!")
		else
			vim.cmd("bd")
		end
	end, { noremap = true, silent = true, desc = "Close current buffer" })
	vim.keymap.set("n", ";a", ":qall<CR>", { noremap = true, silent = true, desc = "Quit all" })
	vim.keymap.set("n", ";e", ":lua MyRefreshFile()<CR>", { noremap = true, silent = true, desc = "Refresh file" })
	vim.keymap.set("n", ";w", "<cmd>lua myWriteFile()<CR>", { noremap = true, silent = true, desc = "Save file" })

	-- Format current buffer with conform.nvim
	vim.keymap.set({ "n", "v" }, "<leader>cf", function()
		local ok, conform = pcall(require, "conform")
		if not ok then
			vim.notify("conform.nvim not loaded!", vim.log.levels.ERROR)
			return
		end
		local formatters = conform.list_formatters()
		if #formatters == 0 then
			vim.notify("No formatters available for this filetype", vim.log.levels.WARN)
			return
		end
		vim.notify("Formatting with: " .. formatters[1].name, vim.log.levels.INFO)
		conform.format({ async = true, lsp_fallback = true })
	end, { desc = "Format buffer" })
end, 500)
vim.o.clipboard = "unnamedplus"

-- Open PDF in Skim, reusing the last window's position/size
vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = "*.pdf",
	callback = function(ev)
		local pdf_path = vim.api.nvim_buf_get_name(ev.buf)
		local saved_bounds = vim.fn.system({
			"osascript", "-e",
			'try\ntell application "Skim" to get bounds of window 1\non error\nreturn ""\nend try',
		})
		saved_bounds = vim.trim(saved_bounds)
		vim.fn.system({ "open", "-g", "-a", "Skim", pdf_path })
		if saved_bounds ~= "" then
			vim.defer_fn(function()
				vim.fn.system({
					"osascript", "-e",
					'tell application "Skim" to set bounds of window 1 to {' .. saved_bounds .. "}",
				})
			end, 500)
		end
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(ev.buf) then
				vim.cmd("bd! " .. ev.buf)
			end
		end, 200)
	end,
})

local function run_in_terminal_app(cmd, app)
	app = app or "terminal"
	if app == "kitty" then
		local escaped = cmd:gsub('\\', '\\\\'):gsub('"', '\\"')
		local script = string.format([[
tell application "System Events"
	set found to false
	if exists process "kitty" then
		tell process "kitty"
			repeat with w in windows
				set wName to name of w
				if wName ends with "zsh" or wName ends with "bash" or wName ends with "fish" or wName ends with "sh" then
					perform action "AXRaise" of w
					set frontmost to true
					delay 0.3
					keystroke "%s"
					key code 36
					set found to true
					exit repeat
				end if
			end repeat
		end tell
	end if
	if not found then
		tell application "kitty" to activate
		delay 0.5
		tell process "kitty"
			set frontmost to true
			keystroke "n" using command down
			delay 0.5
			keystroke "%s"
			key code 36
		end tell
	end if
end tell]], escaped, escaped)
		vim.fn.jobstart({ "osascript", "-e", script }, { detach = true })
	else
		local escaped = cmd:gsub('\\', '\\\\'):gsub('"', '\\"')
		local script = string.format([[
tell application "Terminal"
	activate
	set idleTab to missing value
	set shells to {"bash", "zsh", "fish", "sh", "login"}
	repeat with w in windows
		repeat with t in tabs of w
			if busy of t is false then
				set procList to processes of t
				set allShell to true
				repeat with p in procList
					set isShell to false
					repeat with s in shells
						if p is equal to contents of s then
							set isShell to true
							exit repeat
						end if
					end repeat
					if not isShell then
						set allShell to false
						exit repeat
					end if
				end repeat
				if allShell then
					set idleTab to t
					set frontWindow to w
					exit repeat
				end if
			end if
		end repeat
		if idleTab is not missing value then exit repeat
	end repeat
	if idleTab is not missing value then
		set selected tab of frontWindow to idleTab
		set index of frontWindow to 1
		do script "%s" in idleTab
	else
		do script "%s"
	end if
end tell]], escaped, escaped)
		vim.fn.jobstart({ "osascript", "-e", script }, { detach = true })
	end
end

local claude_sessions_dir = "/Users/maojingwei/baidu/project/claude_settings/.claude/projects/-Users-maojingwei-baidu-project"
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*.jsonl",
	once = false,
	callback = function(ev)
		if vim.b[ev.buf]._claude_resumed then
			return
		end
		local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":p")
		local dir = vim.fn.fnamemodify(file, ":h")
		if dir ~= claude_sessions_dir then
			return
		end
		vim.b[ev.buf]._claude_resumed = true
		local session_id = vim.fn.fnamemodify(file, ":t:r")
		run_in_terminal_app("claude --resume " .. session_id, "kitty")
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	callback = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname ~= "" and vim.bo.buftype == "" and not vim.bo.filetype:match("^Snacks") then
			if vim.fn.filereadable(bufname) == 0 then
				vim.notify("File no longer exists on disk: " .. vim.fn.fnamemodify(bufname, ":."), vim.log.levels.WARN)
			end
		end
	end,
})

vim.keymap.set("n", "fj", function()
	local log = vim.fn.expand("~/hammerspoon_cmd.log")
	OpenOrSwitchToFile(log)
	vim.cmd("edit!")
	vim.cmd("normal! G")
end, { noremap = true, silent = true, desc = "Open hammerspoon cmd log" })

vim.keymap.set("n", "<F5>", function()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" then
		vim.notify("No file to run", vim.log.levels.WARN)
		return
	end
	local cmd = "bash /Users/maojingwei/baidu/project/common_tools/meta_script.sh " .. vim.fn.shellescape(filepath)
	run_in_terminal_app(cmd)
	vim.notify("Running in Terminal.app: " .. cmd)
end, { noremap = true, silent = true, desc = "Run meta_script on current file in Terminal" })

vim.defer_fn(function()
	vim.fn.system({ "/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs", "-c", "hs.reload()" })
end, 500)

local function get_or_create_terminal()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
			local chan = vim.bo[buf].channel
			if chan and chan > 0 then
				return buf, chan
			end
		end
	end
	local cur_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd("tabnew | terminal")
	local buf = vim.api.nvim_get_current_buf()
	local chan = vim.bo[buf].channel
	return buf, chan
end

local function send_to_terminal(text)
	local buf, chan = get_or_create_terminal()
	if not chan or chan <= 0 then
		vim.notify("No terminal channel", vim.log.levels.ERROR)
		return
	end
	vim.fn.chansend(chan, text .. "\n")
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			if vim.api.nvim_win_get_buf(win) == buf then
				vim.api.nvim_set_current_tabpage(tab)
				vim.api.nvim_set_current_win(win)
				return
			end
		end
	end
	vim.cmd("tabnew")
	vim.api.nvim_win_set_buf(0, buf)
end

vim.keymap.set("n", "<leader>r", function()
	send_to_terminal(vim.fn.getline("."))
end, { noremap = true, silent = true, desc = "Run current line in terminal" })

vim.keymap.set("v", "<leader>r", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	vim.schedule(function()
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		local lines = vim.fn.getline(start_line, end_line)
		send_to_terminal(table.concat(lines, "\n"))
	end)
end, { noremap = true, silent = true, desc = "Run selected lines in terminal" })

-- brew install --cask font-jetbrains-mono-nerd-font
-- terminal should also use JetBrainsMono Nerd Font (or JetBrainsMono NF)
