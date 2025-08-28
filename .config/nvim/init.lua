local vim = vim -- Hacky workaround for sumneko_lua being sorta dumb right now. I can fix it better later.
-- copied from https://github.com/folke/lazy.nvim#-installation
local lazypath = vim.fn.stdpath'data' .. "/lazy/lazy.nvim"
-- TODO: mark PHP and composer as not needed?
-- TODO: mark perl as not needed?
-- TODO: these need to be marked as auto-install
-- - prettier
-- - stylelint
-- - vint
-- After that, tell efmls to not ask for them, if they can't be installed.
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system{
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath
	}
	local sitepath = vim.fn.stdpath'data' .. "/site"
	local packer_compiled = vim.fn.stdpath'config' .. "/plugin/packer_compiled.lua"
	local packer_install_path = sitepath .. "/pack/packer"
	if vim.loop.fs_stat(sitepath) and vim.loop.fs_stat(packer_compiled) and vim.loop.fs_stat(packer_install_path) then
		print"Migrating from packer..."
		vim.cmd.sleep()
		vim.fn.delete(sitepath)
		vim.fn.delete(packer_compiled)
	end
end
vim.opt.rtp:prepend(lazypath)

-- TODO: proper git_dir stuff https://github.com/tpope/vim-fugitive/issues/2191

-- if vim.env.VIMRUNNING == "1" then
-- 	print("dummy! read before running (override by setting $VIMRUNNING to \"2\")")
-- 	-- Lua never sleeps
-- 	vim.cmd.sleep()
-- 	-- and isn't a quitter
-- 	vim.cmd.qall{ bang = true }
-- 	-- So vim has to take care of it.
-- elseif vim.env.VIMRUNNING ~= "2" then
-- 	vim.env.VIMRUNNING = 1
-- end

local function configure_nvim_cmp()
	local cmp = require'cmp'
	vim.lsp.config('*', {
		capabilities = require'cmp_nvim_lsp'.default_capabilities(),
	})
	--[[local function has_words_before()

		return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
	end]]
	---@deprecated
	local lsp_zero = require'lsp-zero'
	local formatting = lsp_zero.cmp_format{} -- TODO: move away from lsp_zero here
	do -- We still like lspkind in this house. format with zero, then lspkind. Best of both, hardly any manual config
		local zero_format_fn = formatting.format
		formatting.format = require'lspkind'.cmp_format{
			mode = 'symbol_text',
			before = function (entry, vim_item)
				return zero_format_fn(entry, vim_item)
			end
		}
	end
	cmp.setup{
		--Defaults:https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
		snippet = {
			expand = function(args)
				require'luasnip'.lsp_expand(args.body)
			end,
		},
		mapping = {
			['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
			['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
			['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
			['<C-e>'] = cmp.mapping{
				i = cmp.mapping.abort(),
				c = cmp.mapping.close(),
			},
			-- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#luasnip
			['<Tab>'] = cmp.mapping(function (fallback)
				if cmp.visible() then
					cmp.confirm{ select = true }
				elseif require'luasnip'.expand_or_jumpable() then
					require'luasnip'.expand_or_jump()
				-- TODO: there's currently no way to tell if there's even a possible completion here. If there is, we should use
				--  that, and use the fallback otherwise. See https://github.com/hrsh7th/nvim-cmp/issues/602
				--elseif has_words_before() then
				--	print"tabbed! has words before"
				--	cmp.mapping.complete()
				else
					fallback()
				end
			end, { 'i', 's' }),
			['<S-Tab>'] = cmp.mapping(function (fallback)
				if cmp.visible() then
					cmp.mapping.select_prev_item()
				elseif require'luasnip'.jumpable(-1) then
					require'luasnip'.jump(-1)
				else
					fallback()
				end
			end, { 'i', 's' }),
			['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
			['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' })
		},
		-- TODO: my method of lazy loading doesn't seem to work. It replaces all sources.
		sources = cmp.config.sources({
			{ name = 'nvim_lsp' }, -- can be lazy
			{ name = 'luasnip' }, -- Cannot be lazy
			{ name = 'latex_symbols' }, -- can be lazy
			{ name = 'emoji', insert = true }, -- can be lazy
		--}, {
			{ name = "git" }, -- can be lazy loaded
			{ name = "crates" }, -- can be lazy
			{ name = 'npm', keyword_length = 4 }, -- can be lazy
			{ name = 'nvim_lsp_document_symbol' }, -- can be lazy
			{ name = "fish" }, -- can be lazy
			{ name = "path" }, -- can be lazy
			--{ name = "dictionary", keyword_length = 2 }, -- TODO: seems broken (switcher is deprecated)
			{ name = 'nvim_lua' }, -- can be lazy
		}, {
			{ name = 'buffer' }, -- can be lazy
			{ name = 'cmdline', keyword_length = 2 }, -- Can be lazy
		}--[[, {
			{ name = 'cmdline_history', options = { history_type = ':' } }, -- can be lazy
		}]]),
		sorting = {
			comparators = {
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				cmp.config.compare.score,
				cmp.config.compare.recently_used,
				require'cmp-under-comparator'.under,
				cmp.config.compare.kind,
				cmp.config.compare.sort_text,
				cmp.config.compare.length,
				cmp.config.compare.order,
			},
		},
		formatting = formatting
	}
	-- Use buffer source (then history) for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline({'/', '?'}, {
		sources = cmp.config.sources(
			{ { name = 'buffer' } }, -- can be lazy
			{ { name = 'cmdline_history' } } -- can be lazy
		)
	})
	-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline(':', {
		sources = cmp.config.sources(
			{ { name = 'path' } }, -- can be lazy
			{
				{ name = 'cmdline' }, -- Can be lazy
				{ name = 'cmdline_history' } -- can be lazy
			}
		)
	})
	cmp.setup.cmdline({'@', '='}, {
		sources = { { name = 'cmdline_history' } } -- can be lazy
	})
end

local has_the_command_that_some_call
do
	local theCommandsThatWeKnow = {}
	function has_the_command_that_some_call(tim)
		if theCommandsThatWeKnow[tim]~=nil then
			return theCommandsThatWeKnow[tim]
		end
		local check_cmd = io.popen(string.format("command -v %s", tim))
		local result = nil
		if check_cmd then
			local read_res = check_cmd:read"*all"
			local val = ({check_cmd:close()})[3]
			local it_has_it = #read_res > 0
			theCommandsThatWeKnow[tim] = it_has_it
			result =  it_has_it
		else
			theCommandsThatWeKnow[tim] = false
			result =  false
		end
		if not result then
			-- timmeh stuck in the well!
			vim.notify(
				string.format("the program '%s' is missing. Less functionality will be available.", tim),
				--vim.log.levels.WARN
				vim.log.levels.WARN
			)
		end
		return result
	end
end

-- only load things if npm, pnpm or yarn is present
-- TODO: consider checking for npm, pnpm and  yarn.
-- TODO: consider just checking for node
local function has_npm()
	return has_the_command_that_some_call"npm" and
		has_the_command_that_some_call"node"
end

local function inside_neovimpager()
	local result = pcall(function()
		require'nvimpager'
	end)
	inside_neovimpager = function()
		return result
	end
	return result
end

local function configure_lualine()
	-- BUG: lualine or one of it's deps is using deprecated features
	---@deprecated lsp-zero is unmaintained
	local lsp_zero = require'lsp-zero'
	--                                        █ 🙽 🙼 🙿   🙾
	-- https://github.com/ryanoasis/nerd-fonts/issues/1190
	vim.opt.shortmess:append'S' -- Do not show search count message when searching e.g. '[1/5]'
	local function filename_format(_--[[c]], filename, mod, filetype)
		local icon, _--[[color]]= require'nvim-web-devicons'.get_icon_color(filetype)
		-- icon = c:format_hl(color) .. icon .. c:get_default_hl() -- TODO: color lualine/components/filetype.lua
		return (icon and  icon .. ' ' or '') .. filename .. (mod == 1 and ' ~' or '')
	end
	local custom_filename_component = {
		'filename',
		fmt = function (filename, c)
			local mod = vim.bo.mod
			local filetype = vim.bo.filetype
			return filename_format(c, filename, mod, filetype)
		end,
	}
	require'lualine'.setup{
		options = {
			component_separators = { left = '', right = ''},
			section_separators = { left = ' ', right = ' '}
		},
		inactive_sections = {
			lualine_c = { custom_filename_component }
		},
		sections = {
			lualine_b = {
				-- TODO: do this with mason
				{
					function () return require'lazy.status'.updates() end,
					cond = function () return require'lazy.status'.has_updates() end
				},
				--'hostname',
				'branch', 'diff', 'diagnostics'
				-- TODO: todo count https://github.com/folke/todo-comments.nvim/issues/197
			},
			lualine_c = {
				custom_filename_component,
				'selectioncount',
				function () return require'lsp-status'.status() end,
				-- The below doesn't look good and provides nothing I need
				--function () -- NOTE: this would also need to only load if treesitter is installed (in the system)
				--	return vim.fn['nvim_treesitter#statusline']{indicator_size=20}
				--end
			},
			lualine_y = {
				{
					function () return require'battery'.get_status_line() end,
					cond = function ()
						return vim.o.columns > 120
					end
				},
				'searchcount',
				'progress'
			}
		},
		tabline = {
			lualine_b = {{
				'tabs',
				mode = 1,
				max_length = function () return vim.o.columns end,
				fmt = function (filename, context)
					-- Show ~ if buffer is modified in tab
					local buflist = vim.fn.tabpagebuflist(context.tabnr)
					local winnr = vim.fn.tabpagewinnr(context.tabnr)
					local bufnr = buflist[winnr]
					local mod = vim.fn.getbufvar(bufnr, '&mod')
					local filetype = vim.fn.getbufvar(bufnr, '&filetype')

					return filename_format(context, filename, mod, filetype)
				end,
				cond = function ()
					return vim.fn.tabpagenr'$' > 1
				end
			}}
		},
		-- Each extension "changes statusline appearance for a window/buffer with specified filetypes"
		extensions = { 'fugitive', 'lazy', 'neo-tree' }
	}
	vim.opt.showtabline = 1 --(visible if more than 1 tab)
	-- Here we are getting the icons from the lualine default settings. If you change lualine's config, these icons will
	-- not change with it.
	-- This is horrible. Despicible. Don't do it. It WILL break.
	lsp_zero.set_sign_icons(require"lualine.components.diagnostics.config".symbols.icons)
end

local function tbflatten(tb)
	return vim.iter(tb):flatten():totable()
end

do -- Keymaps and the like
	-- refer to https://github.com/nanotee/nvim-lua-guide

	--vim.lsp.set_log_level("debug")

	-- Which syntaxes would you like to enable highlighting for in vim files?
	vim.g.vimsyn_embed = 'l'

	-- see the docstrings for folded code
	-- TODO: this looks typo-ed and is likely broken
	vim.g.SimpylFold_docstring_preview = 1

	--vim.keymap.set('n', '<Leader>d', vim.diagnostic.goto_next)

	-- TODO: unless there's a conflict, learn the _actual_ shortcuts (and remove these)

	vim.keymap.set('n', '<Leader><Leader>', '<c-^>', {desc="Go back one file in current buffer"})

	-- Map <Esc> to exit terminal-mode (stolen from nvim's :help terminal-input then modified for lua)
	vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {desc='exit terminal mode and convert it back into a buffer'})
	-- Make it a tad easier to change the terminal back to a buffer
	vim.keymap.set('', '<Leader>]', '<C-\\><C-n>', {desc='exit terminal mode and convert it back into a buffer'})

	-- Keyboard shortcut to open nerd tree via currently disabled mod
	--vim.keymap.set('', '<Leader>n', '<Plug>NERDTreeTabsToggle<CR>')

	-- Reccomended keymaps from nvim-lspconfig
	-- https://github.com/neovim/nvim-lspconfig#suggested-configuration
	vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { noremap=true, silent=true, desc="diagnostic open float" })
	-- TODO: deprecated
	vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { noremap=true, silent=true, desc="diagnostic goto prev" })
	-- TODO: deprecated
	vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { noremap=true, silent=true, desc="diagnostic goto next" })
	vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, {
		noremap=true,
		silent=true,
		desc="diagnostic add to locaction list"
	})

	-- Reccomended settings for nvim-cmp
	vim.o.completeopt = 'menu,menuone,noselect'

	vim.o.showmode = false -- Hide the default mode text (e.g. -- INSERT -- below the statusline)
	-- print options
	-- set printoptions=paper:letter

	-- display line numbers
	--  If this is used with [[relativenumber]], then it shows the current lineno on the current line (as opposed to `0`)
	vim.o.number = true
	vim.o.relativenumber = true

	vim.o.wrap = true

	vim.o.tabstop = 4
	vim.o.shiftwidth = 4
	vim.o.backspace = 'indent,eol,start'

	-- Use sys clipboard (see osc52 for ssh clipboard)
	vim.o.clipboard = 'unnamedplus'

	-- Title magic.
	vim.o.title = true

	-- I don't like presssing more most of the time -- Breaks :map
	--vim.o.more = false

	-- This is the global vim refresh interval. Multiple tools, such as
	-- gitgutter and coc reccomend turning this number down. It's measured in
	-- milliseconds, and defaults to 4000
	vim.o.updatetime = 1000

	-- Enable folding
	--vim.o.foldmethod = 'syntax'
	----vim.o.foldmethod = 'indent'
	--- TODO: what about for when treesitter _doesnt_ work? (this should also only load if treesitter is installed as a
	--  system)
	vim.wo.foldmethod= 'expr'
	vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
	vim.wo.foldlevel=99
	vim.wo.foldminlines = 3

	-- Load file automatically when changes happen
	vim.o.autoread = true

	-- Ensure that the cursor is this many chars at lowest from either end of each buffer
	vim.o.scrolloff = 5
	vim.o.sidescrolloff = 5

	--enable syntax highlighting (optimised for dark backgrounds)
	--vim.o.background='dark'

	-- I needed a ruby nvim plugin awhile back. This fixes it.
	-- TODO: instad, mark as not needed?
	vim.g.ruby_host_prog = '~/.bin/neovim-ruby-host'

	vim.api.nvim_create_autocmd("TextYankPost", {
		pattern = "*",
		callback = function()
			vim.highlight.on_yank()
		end
	})
	-- Allow for syntax checking in racket. The catches: Security(?) and lag.
	-- NOTE: LSP is better
	--vim.g.syntastic_enable_racket_racket_checker = 1 -- I want it to check racket file syntax
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		pattern = "*.rkt",
		callback = function()
			vim.o.tabstop = 2
			vim.o.softtabstop = 2
			vim.o.shiftwidth = 2
			vim.o.textwidth = 79
			vim.o.expandtab = true
			vim.o.autoindent = true
			vim.o.fileformat = "unix"
			vim.o.lisp = true
		end
	})


	-- godot support
	do -- TODO: learn how to use vim.filetype.add
		-- HACK: doesn't work in nvim at all ootb, but vim.filetype.add doesn't work for this
		vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
			pattern = "*.gd",
			callback = function ()
				vim.o.filetype = "gdscript"
			end
		})
		-- HACK: gdresource is supported if opened from cli, this lets it work elsewhere. Same issue with vim.filetype.add.
		vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
			pattern = "*.tscn",
			callback = function ()
				vim.o.filetype = "gdresource"
			end
		})
	end
	-- Disable numbers on terminal only.
	--[[ TODO: This will need an autocommand for every buffer, since the setting is inherited when split
	vim.api.nvim_create_autocmd({ "TermOpen" }, {
		pattern = "*",
		callback = function()
			-- TODO: should this be something else? It errors for bo
			vim.o.number = false
			vim.o.relativenumber = false
		end
	})]]
	-- Popup windows tend to be unreadable with a pink background
	--vim.api.nvim_set_hl(0, "Pmenu", {})

	--[[
	-- TODO: if I uncomment this code, java code highlighting breaks
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = 'java',
		callback = function()
			assert(false)
			require'jdtls'.start_or_attach(vim.tbl_extend(
				'force',
				require'lsp-zero.server'.default_config,
				require'lspconfig'.jdtls.config_def.default_config
			))
		end
	})
	--]]
end

local lazy_config = { defaults = { lazy = true }, checker = { enabled = true, notify = false } }

local lazy_plugins = {
	-- Commenting
	--Plug 'tpope/vim-commentary'
	-- The looks of Powerline but faster than:
	-- - Powerline
	-- - Airline
	-- - And the well-known, formerly first-place Lightline
	{ 'nvim-lualine/lualine.nvim', config = configure_lualine, event = "BufEnter" },
	-- The looks of Powerline, but faster
	-- use{
	-- 	'itchyny/lightline.vim',
	-- 	disable = true,
	-- 	--config = configure_lightline,
	-- 	requires = {
	-- 		'vim-fugitive',
	-- 		'lsp-status.nvim'
	-- 	}
	-- }
	-- Indent lines
	{ 'lukas-reineke/indent-blankline.nvim',
		event = "VeryLazy", -- TODO: better lazyness?
		main = "ibl",
		config = function ()
			require"ibl".setup{
				indent = { char = '│', tab_char = '│' },
				scope = { show_start = false, show_end = false }
			}
			local hooks = require"ibl.hooks"
			hooks.register(
				hooks.type.ACTIVE,
				function ()
					-- Because we only set when ibl activiates, it doesn't run for buffers we don't edit.
					-- This also ensures that list is set _after_ ibl makes rendering changes. This prevents clashes.
					vim.opt.list = true
					return true
				end
			)
			-- Line indent markers
			vim.opt.listchars:append"lead:⋅"
			vim.opt.listchars:append"nbsp:⚬"
			vim.opt.listchars:append"tab:  " -- No > chars when ibl is slow
			vim.opt.listchars:append"trail:─"
		end
	},
	-- Super fancy coloring
	--  A companion to windwp/nvim-autopairs that does xml
	{ "windwp/nvim-ts-autotag",
		event = "InsertEnter",
		opts = {}
	},
	{ 'nvim-treesitter/nvim-treesitter',
		-- TODO: only load this if tree-sitter is installed
		--dependencies = "windwp/nvim-ts-autotag",
		main = 'nvim-treesitter.configs',
		branch = 'master', -- TODO: move to incompatible main branch
		opts = {
			sync_install = true,
			auto_install = true -- With this, I don't actually need any list. It lazy-installs this way.
			-- TODO: require `tree-sitter` cli program
		},
		build = ':TSUpdateSync',
		event = 'VeryLazy' -- TODO: better lazyness?
	},
	{ 'rebelot/kanagawa.nvim',
		-- TODO: (low prio) match this and the cmd theme
		lazy = false,
		priority = 1000,
		config = function ()
			vim.cmd.colorscheme'kanagawa'
			--vim.cmd.colorscheme'kanagawa-lotus'
		end
	},
	{ 'ojroques/nvim-osc52',
		-- Copy clipboard even if over ssh
		config = function ()
			require'osc52'.setup{}
			-- Setup a few keymaps so I can copy even if the rest of this plugin is broken
			vim.keymap.set('n', '<leader>c', require'osc52'.copy_operator, {expr = true, desc="osc52 copy operator"})
			vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true, desc="osc52 copy _"})
			vim.keymap.set('n', '<leader>C', '<leader>c', {remap = true, desc="osc52 copy operator alt"})
			vim.keymap.set('v', '<leader>c', require'osc52'.copy_visual, {desc="osc52 copy visual mode operator"})
			vim.keymap.set('v', '<leader>C', '<leader>c', {remap = true, desc="osc52 copy visual mode operator alt"})
			-- Copy text yanked into + (this does work, but hard to use)
			--local function copy()
			--	if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
			--		require'osc52'.copy_register'+'
			--	end
			--end
			--vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
			-- Use this plugin as a clipboard provider TODO: doesn't seem to work
			--local function copy(lines, _)
			--	require'osc52'.copy(table.concat(lines, '\n'))
			--end
			--local function paste()
			--	return {vim.fn.split(vim.fn.getreg'', '\n'), vim.fn.getregtype''}
			--end
			--vim.g.clipboard = {
			--	name = 'osc52',
			--	copy = {['+'] = copy, ['*'] = copy},
			--	paste = {['+'] = paste, ['*'] = paste}
			--}
			--vim.keymap.set('n', '<leader>c', '"+y')
			--vim.keymap.set('n', '<leader>cc', '"+yy')
		end,
		event = "BufEnter"
	},

	-- Git integration
	--  Genral use
	{ 'tpope/vim-fugitive', event = "VeryLazy" }, -- TODO: better lazyness?
	--  Line-per-line indicators and chunk selection
	{ 'lewis6991/gitsigns.nvim',
		opts = {
			on_attach = function(bufnr)
				local gs = require'gitsigns'
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then
						vim.cmd.normal{']c', bang = true}
					else
						gs.nav_hunk'next'
					end
				end, {desc="Git next hunk"})
				map('n', '[c', function()
					if vim.wo.diff then
						vim.cmd.normal{'[c', bang = true}
					else
						gs.nav_hunk'prev'
					end
				end, {desc="Git prev hunk"})
				-- Actions
				map('n', '<leader>hs', gs.stage_hunk, {desc="Git stage hunk"})
				map('n', '<leader>hr', gs.reset_hunk, {desc="Git reset hunk"})

				map('v', '<leader>hs', function()
					gs.stage_hunk {vim.fn.line("."), vim.fn.line("v")}
				end, {desc="Git stage hunk visual"})

				map('v', '<leader>hr', function()
				  gs.reset_hunk{ vim.fn.line'.', vim.fn.line'v' }
				end, {desc="Git reset hunk visual"})

				map('n', '<leader>hS', gs.stage_buffer, {desc="Git stage buffer"})
				map('n', '<leader>hR', gs.reset_buffer, {desc="Git reset buffer"})
				map('n', '<leader>hp', gs.preview_hunk, {desc="Git preview hunk"})
				map('n', '<leader>hi', gs.preview_hunk_inline, {desc="Git preview hunk inline"})

				map('n', '<leader>hb', function()
					gs.blame_line{full=true}
				end, {desc="Git blame line"})

				map('n', '<leader>hd', gs.diffthis, {desc="Git diff this"})

				map('n', '<leader>hD', function()
					gs.diffthis'~'
				end, {desc="Git diff this ~"})

				map('n', '<leader>hQ', function() gs.setqflist'all' end, {desc="Git quickfix all"})
				map('n', '<leader>hq', gs.setqflist, {desc="Git quickfix"})

				-- Toggles
				map('n', '<leader>tb', gs.toggle_current_line_blame, {desc="Git toggle current line blame"})
				map('n', '<leader>td', gs.toggle_deleted, {desc="Git toggle deleted"})
				map('n', '<leader>tw', gs.toggle_word_diff, {desc="Git toggle word diff"})

				-- Text object
				map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {desc="Git select hunk"})
			end
		},
		event = "BufEnter"
	},
	"MunifTanjim/nui.nvim",
	-- Even nicer file management
	{ 'nvim-neo-tree/neo-tree.nvim',
		--branch = "v3.x",
		branch = "main",
		dependencies = {
			--"nvim-lua/plenary.nvim",
			--"nvim-tree/nvim-web-devicons",
			--"MunifTanjim/nui.nvim",
			'vim-rooter'
		},
		init = function ()
			vim.g.neo_tree_remove_legacy_commands = 1
			vim.g.loaded_netrwPlugin = 1 -- Don't load both this and the builtin tree
		end,
		opts = { window = { position = "current" } },
		lazy = false
	},
	{ 'justinhj/battery.nvim',
		--dependencies = {'nvim-tree/nvim-web-devicons', 'nvim-lua/plenary.nvim'},
		opts = {},
		event = "VeryLazy" -- TODO: better lazyness?
	},

	-- Icons
	'nvim-tree/nvim-web-devicons',
	--  LSP breakdown icons and stuff
	'onsails/lspkind-nvim',

	--  This should work on all files (it's python support ain't great)
	--Plug 'khzaw/vim-conceal'
	--Plug 'jamestomasino-forks/vim-conceal' " This one has better javascript support
	--Plug 'Lazerbeak12345/vim-conceal' " This is my blend of a bunch of stuff (my
	--    fork of above)
	-- Ease of use
	{ 'vimlab/split-term.vim', cmd = { "Term", "VTerm", "TTerm" } },
	-- un-recursor
	{ "samjwill/nvim-unception",
		-- BUG: if dbus doesn't know this user is logged in, this plugin breaks
		init = function()
			vim.g.unception_block_while_host_edits = 1
			vim.g.unception_enable_flavor_text = 1
		end,
		lazy = false,
	},
	{ 'airblade/vim-rooter',
		init = function ()
			vim.g.rooter_change_directory_for_non_project_files = 'current'
			vim.g.rooter_patterns = tbflatten{
				has_the_command_that_some_call"git" and { '.git' } or {},
				has_the_command_that_some_call"npm" and { 'package.json' } or {},
				has_the_command_that_some_call"make" and { 'Makefile' } or {},
				has_the_command_that_some_call"luanti" and {
					'mod.conf',
					'modpack.conf',
					'game.conf',
					'texture_pack.conf',
				} or {},
				has_the_command_that_some_call"godot" and {
					"project.godot" -- I must have this one, at least.
				} or {}
			}
		end,
		cond = function ()
			-- dont load if we are in neovimpager
			return not inside_neovimpager()
		end
	},
	--  Start Screen
	{ 'goolord/alpha-nvim',
		--dependencies = {
		--	'nvim-tree/nvim-web-devicons',
		--	'airblade/vim-rooter'
		--},
		lazy = false,
		config = function ()
			require'alpha'.setup(require'alpha.themes.startify'.config)
		end
	},


	-- common dependencie of many nvim plugins
	'nvim-lua/plenary.nvim',

	-- default settings for efmls
	'creativenull/efmls-configs-nvim', --version = 'v1.1.1', },
	-- Interactive eval
	-- use 'Olical/conjure'
	--  TODO: configure this
	--  this might be a problem 987632498629765296987492
	--  This should be added after DAP (due to feature overlap and complexity)

	-- Specific file type compat
	--  General stuff (syntax, etc)
	{ 'sheerun/vim-polyglot', event = "BufEnter" },
	--  Eww's configuration language, yuck
	{ 'elkowar/yuck.vim', event = "BufEnter" },
	{ "folke/todo-comments.nvim",
		-- TODO: is it possible to replace this with something that uses treesitter or LSP?
		--dependencies = "plenary.nvim",
		event = "VeryLazy", -- TODO: better lazyness?
		config = function ()
			local tc = require'todo-comments'
			tc.setup{
				keywords = {
					-- matches the word, so break it on purpose
					FIX = { icon = " " },
					TODO = { icon = "" },
					HACK = { icon = "" },
					WARN = { icon = " " },
					TEST = { icon = " " },
					PERF = { icon = "󰓅 " },
					NOTE = { icon = "󱇗" }
				},
				-- Allow omitting the semicolon
				---- vim regex
				--highlight = { after = "", pattern = [[.*<(KEYWORDS)\s*:?]] },
				---- ripgrep regex
				--search = { pattern = [[\b(KEYWORDS):?]] }, -- TODO: false positives. it it big enough of a problem? Fixable?
			}
			-- https://github.com/folke/todo-comments.nvim#jumping
			vim.keymap.set("n", "]t", function()
				tc.jump_next()
			end, { desc = "Next todo comment" })

			vim.keymap.set("n", "[t", function()
				tc.jump_prev()
			end, { desc = "Previous todo comment" })
		end
	},

	-- Language-server protocol
	-- Must be after language specific things
	{ 'VonHeikemen/lsp-zero.nvim', --- TODO: migrate to 4.x
		branch = 'v3.x',
		init = function ()
			-- Disable automatic setup, we are doing it manually
			vim.g.lsp_zero_extend_cmp = false
			vim.g.lsp_zero_extend_lspconfig = false
		end,
		lazy = true,
		config = false
	},
	{ 'mason-org/mason.nvim',
		lazy = false,
		opts = {
			max_concurrent_installers = require'luv'.available_parallelism(),
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜ ",
					package_uninstalled = "✗"
				}
			}
		}
	},
	{ 'WhoIsSethDaniel/mason-tool-installer.nvim', dependencies = 'mason.nvim' },
	'mason-org/mason-lspconfig.nvim',
	{ 'neovim/nvim-lspconfig',
		event = {"BufReadPre", "BufNewFile"},
		cmd = {"LspInfo", "LspInstall", "LspStart"},
		dependencies = {
			-- TODO: https://lazy.folke.io/developers#best-practices
			--'VonHeikemen/lsp-zero.nvim',
			--'hrsh7th/cmp-nvim-lsp',
			--'mason-org/mason.nvim',
			--'WhoIsSethDaniel/mason-tool-installer.nvim',
			--'mason-org/mason-lspconfig.nvim',
			--'creativenull/efmls-configs-nvim',
			-- TODO: make these into soft dependencies
			--'nvim-lua/lsp-status.nvim',
			--'nvim-lualine/lualine.nvim',
			--'airblade/vim-rooter',
			--'pierreglaser/folding-nvim',
		},
		config = function()
			---@deprecated lsp-zero is unmaintained
			local lsp_zero = require'lsp-zero'

			vim.api.nvim_create_autocmd('LspAttach', {
				desc = 'LSP actions',
				callback = function(event)
					-- TODO: https://lsp-zero.netlify.app/v3.x/language-server-configuration.html#format-using-a-keybinding
					vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = event.buf, desc = "LSP hover" })
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = event.buf, desc = "LSP definition" })
					vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = event.buf, desc = "LSP declaration" })
					vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = event.buf, desc = "LSP implementation" })
					vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, { buffer = event.buf, desc = "LSP type_definition" })
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = event.buf, desc = "LSP references" })
					vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, { buffer = event.buf, desc = "LSP signature_help" })
					vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, { buffer = event.buf, desc = "LSP rename" })
					vim.keymap.set({'n', 'x'}, '<F3>', function ()
						vim.lsp.buf.format{ async = true }
					end, { buffer = event.buf, desc = "LSP format" })
					vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, { buffer = event.buf, desc = "LSP code_action" })
				end,
			})

			vim.lsp.config('*', {
				--capabilities = require'lspconfig'.util.default_config
				capabilities = lsp_zero.get_capabilities()
			})

			-- Installed manually in system.
			vim.lsp.enable'racket_langserver'
			do
				vim.lsp.config('clangd', {
					capabilities = {
						handlers = require'lsp-status'.extensions.clangd.setup(),
						init_options = { clangdFileStatus = true }
					}
				})
				vim.lsp.enable'clangd'
			end

			-- Installed through mason
			-- TODO: assert that all requirements in `:h mason-requirements` are met
			-- https://github.com/nvimdev/guard.nvim -- Linter chains (for if efm doesn't work)
			require'mason-tool-installer'.setup{
				ensure_installed = tbflatten{
					'rustfmt', -- WARNING: reccomends rustup instead of whatever it's doing now (deprecation)
					-- For Java
					--'vscode-java-decompiler',
					--"google-java-format",
					-- "java-debug-adapter"
					--has_the_command_that_some_call"mvn" and {
					--	-- TODO: Blocked by https://github.com/georgewfraser/java-language-server/issues/283
					--	--"java-language-server",
					--},
					--"jdtls", -- developed by eclipse
					--has_the_command_that_some_call"unzip" and {
					--	"gradle_ls",
					--} or {},

					"checkstyle",
					-- This is sumneko_lua. Not my favorite.
					"lua_ls",
					-- TODO: broken
					"ruff", -- Super fast python linting & etc.
					"mypy", -- python type linting
					"django-template-lsp",
					--"curlylint", -- django & etc html template linting
					"djlint", -- django & etc html template linting
					"rust_analyzer",
					"taplo", -- For TOML
					"marksman", -- For markdown
					"efm",
					has_npm() and {
						"stylelint", "prettier",
						"eslint",
						"html",
						"jsonls",
						"yaml-language-server",
						"ts_ls",
						"pyright", -- Everything else python LSP
						"svelte",
						"vimls",
						"ast-grep", -- Rewriting for lots of stuff
						"css-lsp",
						"css-variables-language-server", -- Till css-lsp supports variables, this is needed
						"cssmodules-language-server", -- For when we import css files in react, etc.
						"dot-language-server"
					} or {},
					has_the_command_that_some_call"unzip" and {
						"stylua",
						"selene"
					} or {},
					has_the_command_that_some_call"cargo" and {
						'shellharden'
					} or {},
					has_the_command_that_some_call"luarocks" and {
						'luacheck'
					} or {},
					has_the_command_that_some_call"godot" and {
						"gdtoolkit" -- TODO: configure this
					} or {}
				},
				auto_update = true,
			}
			-- python
			vim.lsp.config('ruff', {
				capabilities = {
					-- disable in favor of pyright
					hoverProvider = false
				}
			})
			-- BUG: doesn't seem to start, these days
			do
				local function formater(name)
					return require("efmls-configs.formatters." .. name)
				end
				local function linter(name)
					return require("efmls-configs.linters." .. name)
				end
				local prettier = formater"prettier"
				local css = { linter"stylelint", prettier }
				local prettier_only = { prettier } -- eslint isn't needed - we have the lsp
				local languages = {
					css = css, less = css, scss = css, sass = css,
					javascript = prettier_only, javascriptreact = prettier_only,
					typescript = prettier_only, typescriptreact = prettier_only,
					html = prettier_only,
					lua = { linter"luacheck", formater"stylua"--[[, linter"selene"]] },
					vim = { linter"vint" }, -- TODO: what does this require
					rust = { formater"rustfmt" },
					sh = { formater"shellharden" },
					fish = { linter"fish", formater"fish_indent" },
					python = { linter"mypy", linter"ruff", formater"ruff" },
					htmldjango = { linter"djlint", formater"djlint" },
					-- BUG: doesn't work. I don't think efm works at all right now, actually
					--java = { formater"google_java_format" }
				}
				vim.lsp.config('efm', {
					settings = {
						-- This is, certianly, the way to go for other things, assuming this even works
						-- TODO: modify rooter_patterns to be the union of all of these language root patterns?
						rootMarkers = vim.g.rooter_patterns,
						languages = languages
					},
					filetypes = vim.tbl_keys(languages)
				})
			end
			-- lua
			vim.lsp.config('lua_ls', lsp_zero.nvim_lua_ls())

			require'mason-lspconfig'.setup {
				automatic_enable = {
					exclude = { "jdtls" }
				},
				-- if this is present, it fools this tool to automatic_enable anything
				-- installed - even if it's installed by something else
				ensure_installed = {},
			}
		end
	},
	{ 'nvim-lua/lsp-status.nvim',
		--dependencies = 'onsails/lspkind-nvim',
		config = function()
			require'lsp-status'.config{
				status_symbol = '', -- The default V breaks some layout stuff.  was the next I used, but it's not needed
				show_filename = false, -- Takes up too much space, redundant
				diagnostics = false, -- lualine actually already displays this information
				kind_labels = require'lspkind'.symbol_map,
			}
			require'lsp-status'.register_progress()
			vim.api.nvim_create_autocmd('LspAttach', {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf
					require'lsp-status'.on_attach(client, bufnr)
				end
			})
			vim.lsp.config('*', {
				capabilities = require'lsp-status'.capabilities
			})
		end,
		module = 'lsp-status'
	},
	-- Update command for mason
	--  https://github.com/RubixDev/mason-update-all#updating-from-cli
	{ 'RubixDev/mason-update-all',
		opts = {},
		cmd = "MasonUpdateAll",
		dependencies = 'mason-org/mason.nvim'
	},
	-- Better folding
	{ 'pierreglaser/folding-nvim',
		-- TODO: this plugin makes use of deprecated functionality?
		config = function()
			vim.api.nvim_create_autocmd('LspAttach', {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					-- This is what it's doing internally. It's very dumb. TODO: it should be using capabilities
					-- I have to do it this way otherwise it complains
					if require'folding'.servers_supporting_folding[client.name] then
						require'folding'.on_attach()
					end
				end
			})
		end,
		event = "VeryLazy" -- TODO: better lazyness?
	},

	-- Completion details (uses LSP)
	'rafamadriz/friendly-snippets',
	{ 'L3MON4D3/LuaSnip',
		config = function ()
			-- Grab things from rafamadriz/friendly-snippets & etc.
			require"luasnip.loaders.from_vscode".lazy_load()
		end,
		--  Pre-configured snippits
		dependencies = 'friendly-snippets'
	},
	{ 'saadparwaiz1/cmp_luasnip',
		-- Snippet source. (There's others out there too)
		dependencies = 'LuaSnip',
	},
	{ 'uga-rosa/cmp-dictionary',
		enabled = false,
		config = function ()
			local dict = require"cmp_dictionary"
			dict.setup{ debug = true }
			dict.switcher{ spelling = { en = "/usr/share/dict/words" } }
		end
	},
	-- Lower the text sorting of completions starting with _
	'lukas-reineke/cmp-under-comparator',
	-- Use /usr/share/dict/words for completion
	{ 'hrsh7th/nvim-cmp',
		config = configure_nvim_cmp,
		event = 'InsertEnter',
		--dependencies  = {
		--	'onsails/lspkind-nvim',
		--	'nvim-lspconfig',
		--	"nvim-lua/plenary.nvim",
		--	'saadparwaiz1/cmp_luasnip',
		--	-- Lower the text sorting of completions starting with _
		--	'lukas-reineke/cmp-under-comparator',
		--	-- Use /usr/share/dict/words for completion
		--	'uga-rosa/cmp-dictionary'
		--}
	},
	-- cmdline history completion
	{ 'dmitmel/cmp-cmdline-history',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp',
		enabled = false
	},
	-- Completion within this buffer
	{ 'hrsh7th/cmp-buffer',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- Completion on the vim.lsp apis
	{ 'hrsh7th/cmp-nvim-lua',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- Path completion
	{ 'hrsh7th/cmp-path',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- VI : command completion
	{ 'hrsh7th/cmp-cmdline',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- Use LSP symbols for buffer-style search
	'hrsh7th/cmp-nvim-lsp',
	{ 'hrsh7th/cmp-nvim-lsp-document-symbol',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = { 'cmp-nvim-lsp', 'nvim-cmp' }
	},
	-- Git completion source
	{ 'petertriho/cmp-git',
		-- BUG: slows things down a ton when I type : in the commit box
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp',
		opts = {}
		--[[config = function ()
			require'cmp_git'.setup{}
			-- TODO: this is per-buffer
			--require'cmp'.setup.buffer{ sources = { { name = "git" } } }
		end]]
	},
	-- crates.io completion source
	{ 'saecki/crates.nvim',
		dependencies = 'nvim-cmp',
		event = "BufRead Cargo.toml",
		config = function()
			require'crates'.setup{ src = { cmp = { enabled = true } } }
			vim.api.nvim_create_autocmd("BufRead", {
				group = vim.api.nvim_create_augroup("CmpSourceCargo", { clear = true }),
				pattern = "Cargo.toml",
				callback = function()
					--require'cmp'.setup.buffer{ sources = { { name = "crates" } } }
				end
			})
		end
	},
	-- package.json completion source
	{ 'David-Kunz/cmp-npm',
		dependencies = { 'plenary.nvim', 'nvim-cmp' },
		event = "BufRead package.json",
		cond = function  ()
			return has_npm()
		end,
		opts = {}
		--[[config = function ()
			require'cmp-npm'.setup{}
			-- TODO: this is per-buffer
			--require'cmp'.setup.buffer{ sources = { { name = 'npm', keyword_length = 4 } } }
		end]]
	},
	-- Fish completion
	{ 'mtoohey31/cmp-fish',
		ft = "fish", -- Only load on fish filetype
		cond = function ()
			-- Only load if fish is present
			return has_the_command_that_some_call"fish"
		end
	},
	-- Pandoc completion
	-- Dude. I literally don't think I've ever used this.
	--[[{
		'jc-doyle/cmp-pandoc-references',
		config = function ()
			require'cmp'.setup.buffer{ sources = { { name = 'pandoc_references' } } }
		end
	},]]
	-- latex symbol completion support (allows for inserting unicode)
	{ 'kdheepak/cmp-latex-symbols',
		event = "VeryLazy" -- TODO: better lazyness?
	},
	-- Emoji completion support
	{ 'hrsh7th/cmp-emoji',
		event = "VeryLazy" -- TODO: better lazyness?
	},
	-- conjure intractive eval completion
	--use 'PaterJason/cmp-conjure' -- TODO: add this to cmp -- this might be a problem 987632498629765296987492
	{ 'mfussenegger/nvim-dap',
		config = function ()
			vim.keymap.set('n', '<F5>', function()
				require'dap'.continue()
			end, {desc="DAP continue"})
			vim.keymap.set('n', '<F10>', function()
				require'dap'.step_over()
			end, {desc="DAP step over"})
			vim.keymap.set('n', '<F11>', function()
				require'dap'.step_into()
			end, {desc="DAP step into"})
			vim.keymap.set('n', '<F12>', function()
				require'dap'.step_out()
			end, {desc="DAP step out"})
			vim.keymap.set('n', '<Leader>b', function()
				require'dap'.toggle_breakpoint()
			end, {desc="DAP toggle breakpoint"})
			vim.keymap.set('n', '<Leader>B', function()
				require'dap'.set_breakpoint()
			end, {desc="DAP set breakpoint"})
			vim.keymap.set('n', '<Leader>lp', function()
				require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
			end, {desc="DAP set logging breakpoint"})
			vim.keymap.set('n', '<Leader>dr', function()
				require'dap'.repl.open()
			end, {desc="DAP open REPL"})
			vim.keymap.set('n', '<Leader>dl', function()
				require'dap'.run_last()
			end, {desc="DAP run last"})
			vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
				require'dap.ui.widgets'.hover()
			end, {desc="DAP eval under the cursor into hover."})
			vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
				require'dap.ui.widgets'.preview()
			end, {desc="DAP eval under the cursor into window."})
			vim.keymap.set('n', '<Leader>df', function()
				local widgets = require'dap.ui.widgets'
				widgets.centered_float(widgets.frames)
			end, {desc='DAP view stack frames'})
			vim.keymap.set('n', '<Leader>ds', function()
				local widgets = require'dap.ui.widgets'
				widgets.centered_float(widgets.scopes)
			end, {desc='DAP view current scope'})

			local dap = require"dap"
			if has_the_command_that_some_call"godot" then
				-- copied directly from
				-- https://github.com/niscolas/nvim-godot/blob/main/nvim_config/lua/package_manager_config.lua
				-- so this godot dap config is under MIT
				dap.adapters.godot = {
					type = "server",
					host = "127.0.0.1",
					port = 6006,
				}
				dap.configurations.gdscript = {
					{
						launch_game_instance = false,
						launch_scene = false,
						name = "Launch scene",
						project = "${workspaceFolder}",
						request = "launch",
						type = "godot",
					},
				}
			end
		end
	},
	{ "jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			'nvim-lspconfig', -- Mason needs to be setup first
			'nvim-dap',
		},
		--event = 'BufEnter',
		event = "VeryLazy", -- TODO: better lazyness?
		config = function ()
			require'mason-nvim-dap'.setup{
				ensure_installed = tbflatten{
					"js", "python",
					-- TODO: this needs to be automatic
					has_the_command_that_some_call"unzip" and {
						"codelldb", "puppet", "cppdbg",
						"bash",
						-- For Java
						--"javatest", "javadbj", -- java-debug-adapter
					} or {},
					has_npm() and {
						"firefox", "chrome",
						"node2",
						"mock",
					} or {}
				},
				automatic_installation = true,
				handlers = {}
			}
		end
	},
	--{ 'mfussenegger/nvim-jdtls', ft = "java", dependencies = 'nvim-cmp' },
	--[[{
		-- This plugin does work, however it is made for modifying pairs in pre-exsisting code. Very nice, but doesn't do cmp
		-- things.
		"kylechui/nvim-surround",
		version = "*", -- Omit to use `main` branch for latest features.
		event = "VeryLazy", -- TODO: better lazyness?
		config = function ()
			require"nvim-surround".setup{
			}
		end
	},]]
	{ "windwp/nvim-autopairs",
		-- Place pairs after typing, ex { causes } to appear.
		event = "VeryLazy",
		opts = {
			fast_wrap = {
				map = '<M-r>' -- <M-e> is to open the default GUI explorer in my WM
			}
		}
	},
	(
		-- TODO: merge these tables, reduce redundant code
		-- TODO: unmaintained.
		has_npm() and {
			-- install with npm
			"iamcco/markdown-preview.nvim",
			cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
			build = "cd app && npm i && git restore .",
			init = function()
				vim.g.mkdp_filetypes = { "markdown" }
			end,
			ft = { "markdown" },
		} or {
			-- install without yarn or npm
			"iamcco/markdown-preview.nvim",
			cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
			ft = { "markdown" },
			build = function() vim.fn["mkdp#util#install"]() end,
		}
	),
	--[[
	{
		-- TODO: could support more filetypes
		"toppair/peek.nvim",
		event = { "VeryLazy" },
		build = "deno task --quiet build:fast",
		config = function()
			require"peek".setup()
			vim.api.nvim_create_user_command("PeekOpen", require"peek".open, {})
			vim.api.nvim_create_user_command("PeekClose", require"peek".close, {})
		end,
		cond = function () return has_the_command_that_some_call"deno" end
	},]]
	{ 'liuchengxu/graphviz.vim', lazy = false }, -- This package is already lazy
}
require("lazy").setup(lazy_plugins, lazy_config)
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
