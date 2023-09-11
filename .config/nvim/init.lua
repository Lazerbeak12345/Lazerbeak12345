local vim = vim -- Hacky workaround for sumneko_lua being sorta dumb right now. I can fix it better later.
-- copied from https://github.com/folke/lazy.nvim#-installation
local lazypath = vim.fn.stdpath'data' .. "/lazy/lazy.nvim"
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

if vim.env.VIMRUNNING == "1" then
	print("dummy! read before running (override by setting $VIMRUNNING to \"2\")")
	-- Lua never sleeps
	vim.cmd.sleep()
	-- and isn't a quitter
	vim.cmd.qall{ bang = true }
	-- So vim has to take care of it.
elseif vim.env.VIMRUNNING ~= "2" then
	vim.env.VIMRUNNING = 1
end

local function configure_nvim_cmp()
	-- TODO nvim-lsp source is broken
	local cmp = require'cmp'
	--[[local function has_words_before()
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
	end]]
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
				-- TODO there's currently no way to tell if there's even a possible completion here. If there is, we should use
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
		sources = cmp.config.sources({
			{ name = 'nvim_lsp' },
			{ name = 'luasnip' },
			{ name = 'latex_symbols' },
			{ name = 'emoji', insert = true },
		--}, {
			{ name = "git" },
			{ name = "crates" },
			{ name = 'npm', keyword_length = 4 },
			{ name = 'pandoc_references' },
			{ name = 'nvim_lsp_document_symbol' },
			{ name = "fish" },
			{ name = "path" },
			{ name = "dictionary", keyword_length = 2 }, -- TODO: seems broken
			{ name = 'nvim_lua' },
		}, {
			{ name = 'buffer' },
			{ name = 'cmdline', keyword_length = 2 },
		}--[[, {
			{ name = 'cmdline_history', options = { history_type = ':' } },
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
		formatting = {
			format = require'lspkind'.cmp_format{
				mode = 'symbol_text',
				before = function (entry, vim_item)
					-- Not as pretty as before but much more reliable
					vim_item.menu = "[" .. entry.source.name .. "]"
					return vim_item
				end
			},
		},
	}
	-- Use buffer source (then history) for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline({'/', '?'}, {
		sources = cmp.config.sources(
			{ { name = 'buffer' } },
			{ { name = 'cmdline_history' } }
		)
	})
	-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline(':', {
		sources = cmp.config.sources(
			{ { name = 'path' } },
			{
				{ name = 'cmdline' },
				{ name = 'cmdline_history' }
			}
		)
	})
	cmp.setup.cmdline({'@', '='}, {
		sources = { { name = 'cmdline_history' } }
	})
end

local function configure_lsp_status()
	local lsp_status = require'lsp-status'
	lsp_status.config{
		status_symbol = '', -- The default V breaks some layout stuff.  was the next I used, but it's not needed
		show_filename = false, -- Takes up too much space, redundant
		diagnostics = false, -- lualine actually already displays this information
		kind_labels = require'lspkind'.symbol_map,
	}
	lsp_status.register_progress()
end

local function configuire_lspconfig()
	local function lsp_keybindings(_client, bufnr)
		-- Reccomended keymaps from nvim-lspconfig
		-- https://github.com/neovim/nvim-lspconfig#suggested-configuration
		local bufopts = { noremap=true, silent=true, buffer=bufnr }
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
		vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
		vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
		vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
		vim.keymap.set('n', '<space>wl', function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, bufopts)
		vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
		vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
		vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
		vim.keymap.set('n', '<space>f', function()
			vim.lsp.buf.format { async = true }
		end, bufopts)
	end
	local default_args={
		on_attach = function(...)
			require'lsp-status'.on_attach(...)
			require'folding'.on_attach(...)
			lsp_keybindings(...)
		end,
	}
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = vim.tbl_extend('keep', capabilities, require'lsp-status'.capabilities)
	capabilities = vim.tbl_extend('keep', capabilities, require'cmp_nvim_lsp'.default_capabilities())
	default_args.capabilities = capabilities
	-- Installed manually in system.
	require'lspconfig'.racket_langserver.setup(default_args)
	require'lspconfig'.clangd.setup({
		on_attach = default_args.on_attach,
		capabilities = vim.tbl_extend('keep', capabilities, {
			handlers = require'lsp-status'.extensions.clangd.setup(),
			init_options = { clangdFileStatus = true }
		})
	})
	-- Installed through mason
	require'mason'.setup{
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗"
			}
		}
	}
	-- Style rule: All sources _must_ link to the documentation for each source.
	-- Must also include what it does.
	-- https://github.com/nvimdev/guard.nvim -- Linter chains (for if efm doesn't work)
	local function efm ()
		local function efm_formatter(name)
			return require("efmls-configs.formatters." .. name)
		end
		local function efm_linter(name)
			return require("efmls-configs.linters." .. name)
		end
		local default_langs = require"efmls-configs.defaults".languages()
		require'lspconfig'.efm.setup{
			on_attach = default_args.on_attach,
			capabilities = capabilities,
			settings = {
				-- TODO can this be used elsewhere?
				rootMarkers = {".git/"},
				languages = vim.tbl_extend("force", default_langs, {
					rust = { efm_formatter"rustfmt" },
					-- We want both luacheck and selene.
					lua = vim.tbl_extend("keep", default_langs.lua, { efm_linter"selene" }),
					sh = { efm_formatter"shellharden" },
					fish = { efm_linter"fish", efm_formatter"fish_indent" }
					-- TODO alex, editorconfig_checker
					-- TODO automatic_installation?
					-- TODO dotenv_linter, tsc, printenv
				})
			}
		}
	end
	local lsp_installed = {
		-- This is sumneko_lua. Not my favorite.
		-- TODO needs to know the root dir only fails to find it on it's own when the first buffer is a lua file.
		--  Not related to rooter
		-- can be short-term fixed by running :LspStart lua_ls when editing this file
		"lua_ls",
		"ruff_lsp", -- Super fast python linting & etc.
		"rust_analyzer",
		"taplo", -- For TOML
		"marksman", -- For markdown
		"efm"
	}
	local lsp_installed_npm = { -- TODO: make this automatic
		"eslint",
		"html",
		"jsonls",
		"tsserver",
		"pyright", -- Everything else python LSP
		"svelte",
		"vimls"
	}
	local check_npm = io.popen"command -v npm"
	local has_npm = nil
	if check_npm then
		check_npm:read"*all"
		has_npm = ({check_npm:close()})[3]
	end
	if has_npm then
		for _, name in ipairs(lsp_installed_npm) do
			lsp_installed[#lsp_installed+1] = name
		end
	end
	require'mason-lspconfig'.setup{
		automatic_installation = true,
		ensure_installed = lsp_installed,
		handlers = {
			function (server_name) -- default handler (optional)
				require'lspconfig'[server_name].setup(default_args)
			end,
			ruff_lsp = function ()
				require'lspconfig'.ruff_lsp.setup {
					on_attach = default_args.on_attach,
					capabilities = vim.tbl_extend('keep', capabilities, {
						-- Pyright does it better
						hoverProvider = false
					})
				}
			end,
			efm = efm
		}
	}
end

local function configure_lualine()
	--                                        █ 🙽 🙼 🙿   🙾
	-- https://github.com/ryanoasis/nerd-fonts/issues/1190
	vim.opt.shortmess:append'S' -- Do not show search count message when searching e.g. '[1/5]'
	require'lualine'.setup{
		options = {
			component_separators = { left = '', right = ''},
			section_separators = { left = ' ', right = ' '}
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
				'filename',
				'selectioncount',
				function () return require'lsp-status'.status() end
			},
			lualine_y = { 'searchcount', 'progress' }
		},
		tabline = {
			lualine_b = {{
				'tabs',
				mode = 1,
				max_length = function () return vim.o.columns end,
				fmt = function (name, context)
					-- Show ~ if buffer is modified in tab
					local buflist = vim.fn.tabpagebuflist(context.tabnr)
					local winnr = vim.fn.tabpagewinnr(context.tabnr)
					local bufnr = buflist[winnr]
					local mod = vim.fn.getbufvar(bufnr, '&mod')

					return name .. (mod == 1 and ' ~' or '')
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
end

do -- Keymaps and the like
	-- refer to https://github.com/nanotee/nvim-lua-guide

	--vim.lsp.set_log_level("debug")

	-- Which syntaxes would you like to enable highlighting for in vim files?
	vim.g.vimsyn_embed = 'l'

	-- Inline diagnostic alerts
	vim.diagnostic.config{ severity_sort = true, virtual_text = { prefix = '🛈 ' } }

	-- see the docstrings for folded code
	vim.g.SimpylFold_docstring_preview = 1

	--vim.keymap.set('n', '<Leader>d', vim.diagnostic.goto_next)

	-- Enable folding with the spacebar (twice now, to allow lspconfig things)
	vim.keymap.set('n', '<space><space>', 'za')

	-- Go back one file in current buffer
	vim.keymap.set('n', '<Leader><Leader>', '<c-^>')

	-- Map <Esc> to exit terminal-mode (stolen from nvim's :help terminal-input then modified for lua)
	vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
	-- Make it a tad easier to change the terminal back to a buffer
	vim.keymap.set('', '<Leader>]', '<C-\\><C-n>')

	-- Keyboard shortcut to open nerd tree via currently disabled mod
	--vim.keymap.set('', '<Leader>n', '<Plug>NERDTreeTabsToggle<CR>')

	-- Reccomended keymaps from nvim-lspconfig
	-- https://github.com/neovim/nvim-lspconfig#suggested-configuration
	do
		local opts = { noremap=true, silent=true }
		vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
		vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
		vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
		vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)
	end

	do -- https://github.com/folke/todo-comments.nvim#jumping
		vim.keymap.set("n", "]t", function()
			require'todo-comments'.jump_next()
		end, { desc = "Next todo comment" })

		vim.keymap.set("n", "[t", function()
			require'todo-comments'.jump_prev()
		end, { desc = "Previous todo comment" })
	end

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
	vim.o.foldmethod = 'syntax'
	--vim.o.foldmethod = 'indent'
	--TODO set foldexpr to nvim_treesitter#foldexpr() https://www.reddit.com/r/neovim/comments/15jxqgn/i_dont_get_why_treesitter_is_a_big_deal_and_at/jv2u0eq/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
	vim.o.foldlevel=99
	vim.o.foldminlines = 3

	-- Load file automatically when changes happen
	vim.o.autoread = true

	--enable syntax highlighting (optimised for dark backgrounds)
	--vim.o.background='dark'

	-- I needed a ruby nvim plugin awhile back. This fixes it.
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
	-- Disable numbers on terminal only.
	vim.api.nvim_create_autocmd({ "TermOpen" }, {
		pattern = "*",
		callback = function()
			vim.o.number = false
			vim.o.relativenumber = false
		end
	})
	-- Popup windows tend to be unreadable with a pink background
	--vim.api.nvim_set_hl(0, "Pmenu", {})
	vim.g.indent_blankline_filetype_exclude = { 'alpha', 'lspinfo', 'checkhealth', 'help', 'man', '' }
	-- TODO this doesn't work. (And I have no idea why. I'll just live with it for now. The above is only defined in this
	-- ugly way to facilitate this.
	--vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	--	--pattern = exclude,
	--	pattern = "*",
	--	callback = function ()
	--		print"asdf"
	--		for _, v in pairs(vim.g.indent_blankline_filetype_exclude) do
	--			if v == vim.bo.filetype then
	--				--vim.opt.list = false
	--				--vim.bo.list = false
	--			end
	--		end
	--	end
	--})
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
	{
		'lukas-reineke/indent-blankline.nvim',
		event = "VeryLazy",
		config = function ()
			vim.opt.list = true
			vim.opt.listchars:append"lead:⋅"
			vim.opt.listchars:append"tab:  "
			require'indent_blankline'.setup {
				show_first_indent_level = false,
				use_treesitter = true,
				show_current_context = true,
				context_highlight_list = {'Label'}
			}
			vim.cmd.IndentBlanklineRefresh()
		end
	},
	-- Super fancy coloring
	{
		'nvim-treesitter/nvim-treesitter',
		--opts = ,
		config = function ()
			require'nvim-treesitter.configs'.setup{
				ensure_installed = {
					"bash",
					"c",
					"cmake",
					"commonlisp",
					"cpp",
					"css",
					"diff",
					"dot",
					"fennel",
					"fish",
					"gdscript",
					"git_config",
					"git_rebase",
					"gitattributes",
					"gitcommit",
					"gitignore",
					"godot_resource",
					"html",
					"javascript",
					"json",
					"json5",
					"jsonc",
					"lua",
					"make",
					"markdown",
					"markdown_inline",
					"python",
					"racket",
					"rust",
					"scheme",
					"scss",
					"svelte",
					"toml",
					"tsx",
					"typescript",
					"vim",
					"vimdoc",
					"vue",
					"yaml",
					"yuck",
				},
				--ensure_installed = "all", -- Very slow to install everything
				sync_install = true,
				auto_install = true
			}
		end,
		build = ':TSUpdateSync',
		event = 'VeryLazy'
	},
	{
		-- TODO (low prio) match this and the cmd theme
		'rebelot/kanagawa.nvim',
		lazy = false,
		priority = 1000,
		config = function ()
			vim.cmd.colorscheme'kanagawa'
		end
	},
	{
		-- Copy clipboard even if over ssh
		'ojroques/nvim-osc52',
		config = function ()
			require'osc52'.setup{}
			-- Setup a few keymaps so I can copy even if the rest of this plugin is broken
			vim.keymap.set('n', '<leader>c', require'osc52'.copy_operator, {expr = true})
			vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
			vim.keymap.set('n', '<leader>C', '<leader>c', {remap = true})
			vim.keymap.set('v', '<leader>c', require'osc52'.copy_visual)
			vim.keymap.set('v', '<leader>C', '<leader>c', {remap = true})
			-- Copy text yanked into + (this does work, but hard to use)
			--local function copy()
			--	if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
			--		require'osc52'.copy_register'+'
			--	end
			--end
			--vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
			-- Use this plugin as a clipboard provider TODO doesn't seem to work
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
	{ 'tpope/vim-fugitive', event = "VeryLazy" },
	--  Line-per-line indicators and chunk selection
	{
		'lewis6991/gitsigns.nvim',
		opts = {
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then return ']c' end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return '<Ignore>'
				end, {expr=true})
				map('n', '[c', function()
					if vim.wo.diff then return '[c' end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return '<Ignore>'
				end, {expr=true})
				-- Actions
				map('n', '<leader>hs', gs.stage_hunk)
				map('n', '<leader>hr', gs.reset_hunk)
				map('v', '<leader>hs', function()
					gs.stage_hunk {vim.fn.line("."), vim.fn.line("v")}
				end)
				map('v', '<leader>hr', function()
					gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")}
				end)
				map('n', '<leader>hS', gs.stage_buffer)
				map('n', '<leader>hu', gs.undo_stage_hunk)
				map('n', '<leader>hR', gs.reset_buffer)
				map('n', '<leader>hp', gs.preview_hunk)
				map('n', '<leader>hb', function()
					gs.blame_line{full=true}
				end)
				map('n', '<leader>tb', gs.toggle_current_line_blame)
				map('n', '<leader>hd', gs.diffthis)
				map('n', '<leader>hD', function()
					gs.diffthis('~')
				end)
				map('n', '<leader>td', gs.toggle_deleted)
				-- Text object
				map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
			end
		},
		event = "BufEnter"
	},
	-- Even nicer file management
	{
		'nvim-neo-tree/neo-tree.nvim',
		branch = "v2.x", -- TODO migrate to v3
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
		config = function ()
			vim.g.neo_tree_remove_legacy_commands = 1
			vim.g.loaded_netrwPlugin = 1 -- Don't load both this and the builtin tree
			local completion_kinds = require'lspkind'.symbol_map -- Completion-kinds:Document-kinds not a 1:1 map
			require'neo-tree'.setup{
				-- These icons below only need to be specified in neo-tree v2
				default_component_configs = {
					diagnostics = {
						symbols = {
							-- Just these icons still need set even after that upgrade
							error = " ",
							warn = " ",
							info =" ",
							hint = "" -- TODO: This icon isn't displaying correctly.
						}
					},
					icon = { folder_empty = "󰜌", folder_empty_open = "󰜌" },
					git_status = { symbols = { renamed   = "󰁕", unstaged  = "󰄱" } }
				},
				document_symbols = { kinds = {
					File = { icon = completion_kinds.File, hl = "Tag" },
					Namespace = { icon = completion_kinds.Module, hl = "Include" },
					Package = { icon = "󰏖", hl = "Label" },
					Class = { icon = completion_kinds.Class, hl = "Include" },
					Property = { icon = completion_kinds.Property, hl = "@property" },
					Enum = { icon = completion_kinds.Enum, hl = "@number" },
					Function = { icon = completion_kinds.Function, hl = "Function" },
					String = { icon = completion_kinds.Text, hl = "String" },
					Number = { icon = completion_kinds.Value, hl = "Number" },
					Array = { icon = "󰅪", hl = "Type" },
					Object = { icon = "󰅩", hl = "Type" },
					Key = { icon = completion_kinds.Keyword, hl = "" },
					Struct = { icon = completion_kinds.Struct, hl = "Type" },
					Operator = { icon = completion_kinds.Operator, hl = "Operator" },
					TypeParameter = { icon = completion_kinds.TypeParameter, hl = "Type" },
					StaticMethod = { icon = completion_kinds.Method, hl = 'Function' }
				} },
				-- Add this section only if you've configured source selector. (I havent)
				source_selector = { sources = {
					{ source = "filesystem", display_name = " 󰉓 Files " },
					{ source = "git_status", display_name = " 󰊢 Git " },
				} },
			}
		end,
		lazy = false
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
	{
		'airblade/vim-rooter',
		config = function ()
			vim.g.rooter_change_directory_for_non_project_files = 'current'
			-- vim.g.rooter_patterns = ['.git', 'mod.conf', 'modpack.conf','game.conf','texture_pack.conf']
		end,
		lazy = false
	},
	--  Start Screen
	{
		'goolord/alpha-nvim', dependencies = 'nvim-tree/nvim-web-devicons', lazy = false,
		config = function () require'alpha'.setup(require'alpha.themes.startify'.config) end
	},


	-- common dependencie of many nvim plugins
	'nvim-lua/plenary.nvim',
	{
		'creativenull/efmls-configs-nvim',
		--version = 'v1.1.1',
		--dependencies = { 'neovim/nvim-lspconfig' },
		event = "VeryLazy"
	},
	-- Interactive eval
	-- use 'Olical/conjure'
	--  TODO configure this
	--  this might be a problem 987632498629765296987492
	--  This should be added after DAP (due to feature overlap and complexity)

	-- Specific file type compat
	--  General stuff (syntax, etc)
	{ 'sheerun/vim-polyglot', event = "BufEnter" },
	--  Eww's configuration language, yuck
	{ 'elkowar/yuck.vim', event = "BufEnter" },
	{
		"folke/todo-comments.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		opts = {
			keywords = {
				-- matches the word, so break it on purpose
				['F'..'IX'] = { icon = "" },
				['T'..'ODO'] = { icon = "" },
				['H'..'ACK'] = { icon = "" },
				['W'..'ARN'] = { icon = "" },
				['T'..'EST'] = { icon = "" },
				['P'..'ERF'] = { icon = "󰓅" },
				['N'..'OTE'] = { icon = "󱇗" }
			},
			-- vim regex
			highlight = { after = "", pattern = [[.*<(KEYWORDS)\s*:?]] },
			-- ripgrep regex
			search = { pattern = [[\b(KEYWORDS):?]] }, -- TODO false positives. it it big enough of a problem? Fixable?
		},
		event = "VeryLazy"
	},

	-- Language-server protocol
	-- Must be after language specific things
	{
		'neovim/nvim-lspconfig',
		config = configuire_lspconfig,
		module = {
			'lspconfig',
			--'lsp-status',
			'cmp_nvim_lsp',
			"mason.nvim",
			'mason-lspconfig.nvim',
		},
		dependencies = 'creativenull/efmls-configs-nvim',
		event = "VeryLazy"
	},
	{
		'nvim-lua/lsp-status.nvim',
		config = configure_lsp_status,
		module = 'lsp-status',
		dependencies = "lualine.nvim"
	},
	-- Automate installing some language-servers
	{ 'williamboman/mason.nvim', event = "VeryLazy" },
	{ 'williamboman/mason-lspconfig.nvim', event = "VeryLazy" },
	-- Update command for mason
	--  https://github.com/RubixDev/mason-update-all#updating-from-cli
	{ 'RubixDev/mason-update-all', opts = {}, event = "BufEnter" },
	-- Better folding
	'pierreglaser/folding-nvim',

	-- Completion details (uses LSP)
	{
		'hrsh7th/cmp-nvim-lsp',
		dependencies = {
			'hrsh7th/nvim-cmp',
			config = configure_nvim_cmp,
			dependencies  = {
				'saadparwaiz1/cmp_luasnip',
				-- Snippet source. (There's others out there too)
				{
					'L3MON4D3/LuaSnip',
					config = function ()
						-- Grab things from rafamadriz/friendly-snippets & etc.
						require"luasnip.loaders.from_vscode".lazy_load()
					end,
					--  Pre-configured snippits
					dependencies = 'rafamadriz/friendly-snippets'
				},
				'hrsh7th/cmp-cmdline',
				'hrsh7th/cmp-path',
				'hrsh7th/cmp-buffer',
				-- Lower the text sorting of completions starting with _
				'lukas-reineke/cmp-under-comparator',
				-- Git completion source
				{ 'petertriho/cmp-git', opts = {} },
				-- latex symbol completion support (allows for inserting unicode)
				'kdheepak/cmp-latex-symbols',
				-- Emoji completion support
				'hrsh7th/cmp-emoji',
				-- Pandoc completion
				'jc-doyle/cmp-pandoc-references',
				-- cmdline history completion
				--Plug 'dmitmel/cmp-cmdline-history'
				-- Use LSP symbols for buffer-style search
				'hrsh7th/cmp-nvim-lsp-document-symbol',
				-- Completion on the vim.lsp apis
				'hrsh7th/cmp-nvim-lua',
				-- Use /usr/share/dict/words for completion
				{
					'uga-rosa/cmp-dictionary',
					config = function ()
						local dict = require"cmp_dictionary"
						dict.setup{ debug = true }
						dict.switcher{ spelling = { en = "/usr/share/dict/words" } }
					end
				}
			}
		}
	},
	-- crates.io completion source
	{ 'saecki/crates.nvim', opts = {}, event = "BufRead Cargo.toml" },
	-- package.json completion source
	{ 'David-Kunz/cmp-npm', opts = {}, dependencies = 'plenary.nvim', event = "BufRead package.json" },
	-- Fish completion
	{
		'mtoohey31/cmp-fish',
		ft = "fish", -- Only load on fish filetype
		cond = function ()
			-- Only load if fish is present
			local check_fish = io.popen"command -v fish"
			local has_fish = nil
			if check_fish then
				check_fish:read"*all"
				has_fish = ({check_fish:close()})[3]
			end
			return has_fish and true or false -- Convert from truthy to bool
		end
	},
	-- conjure intractive eval completion
	--use 'PaterJason/cmp-conjure' -- TODO add this to cmp -- this might be a problem 987632498629765296987492
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			'neovim/nvim-lspconfig', -- Mason needs to be setup first
			{
				'mfussenegger/nvim-dap',
				config = function ()
					vim.keymap.set('n', '<F5>', function()
						require'dap'.continue()
					end)
					vim.keymap.set('n', '<F10>', function()
						require'dap'.step_over()
					end)
					vim.keymap.set('n', '<F11>', function()
						require'dap'.step_into()
					end)
					vim.keymap.set('n', '<F12>', function()
						require'dap'.step_out()
					end)
					vim.keymap.set('n', '<Leader>b', function()
						require'dap'.toggle_breakpoint()
					end)
					vim.keymap.set('n', '<Leader>B', function()
						require'dap'.set_breakpoint()
					end)
					vim.keymap.set('n', '<Leader>lp', function()
						require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
					end)
					vim.keymap.set('n', '<Leader>dr', function()
						require'dap'.repl.open()
					end)
					vim.keymap.set('n', '<Leader>dl', function()
						require'dap'.run_last()
					end)
					vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
						require'dap.ui.widgets'.hover()
					end)
					vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
						require'dap.ui.widgets'.preview()
					end)
					vim.keymap.set('n', '<Leader>df', function()
						local widgets = require'dap.ui.widgets'
						widgets.centered_float(widgets.frames)
					end)
					vim.keymap.set('n', '<Leader>ds', function()
						local widgets = require'dap.ui.widgets'
						widgets.centered_float(widgets.scopes)
					end)
				end
			}
		},
		event = 'BufEnter',
		opts = {
			ensure_installed = { "js", "bash", "node2", "chrome", "cppdbg", "mock", "puppet", "python", "firefox", "codelldb" },
			handlers = {}
		}
	},
}
require("lazy").setup(lazy_plugins, lazy_config)
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
