local vim = vim -- Hacky workaround for sumneko_lua being sorta dumb right now. I can fix it better later.
-- copied from https://github.com/folke/lazy.nvim#-installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
  local sitepath = vim.fn.stdpath("data") .. "/site"
  local packer_compiled = vim.fn.stdpath("config") .. "/plugin/packer_compiled.lua"
  local packer_install_path = sitepath .. "../pack/packer/start/packer.nvim"
  if vim.loop.fs_stat(sitepath) and vim.loop.fs_stat(packer_compiled) and vim.loop.fs_stat(packer_install_path) then
	  print("Migrating from packer...")
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
		}, {
			{ name = "dictionary", keyword_length = 2 },
			{ name = 'nvim_lua' },
			{ name = 'buffer' },
			{ name = 'cmdline' },
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
	require'mason-null-ls'.setup{
		automatic_installation = true,
		ensure_installed = {
			--  https://github.com/get-alex/alex
			--  Catch insensitive, inconsiderate writing.
			'alex',
			--  https://github.com/editorconfig-checker/editorconfig-checker
			--  A tool to verify that your files are in harmony with your `.editorconfig`.
			'editorconfig_checker',
			--  https://kampfkarren.github.io/selene/
			--  Command line tool designed to help write correct and idiomatic Lua code.
			'selene',
			--  https://github.com/Vimjas/vint
			--  Linter for Vimscript.
			--'vint, -- Broken. Causes packer bug.
			--  https://github.com/rust-lang/rustfmt
			--  A tool for formatting rust code according to style guidelines.
			'rustfmt',
			--  https://github.com/anordal/shellharden
			--  Hardens shell scripts by quoting variables, replacing `function_call` with `$(function_call)`, and more.
			'shellharden',
			--  https://github.com/JohnnyMorganz/StyLua
			--  An opinionated code formatter for Lua.
			'stylua',
			--  https://github.com/mpeterv/luacheck
			--  A tool for linting and static analysis of Lua code.
			"luacheck",
		},
		handlers = {
			function(source_name, methods)
				-- To keep the original functionality of `automatic_setup = true`
				require'mason-null-ls.automatic_setup'(source_name, methods)
			end,
			--stylua = function(source_name, methods)
			--	null_ls.register(null_ls.builtins.formatting.stylua)
			--end,
		}
	}
	require'null-ls'.setup{
		sources = {
			-- Anything not supported by mason.
			--
			--  https://github.com/dotenv-linter/dotenv-linter
			--  Lightning-fast linter for .env files.
			require'null-ls'.builtins.diagnostics.dotenv_linter,
			--  https://github.com/fish-shell/fish-shell
			--  Basic linting is available for fish scripts using `fish --no-execute`.
			require'null-ls'.builtins.diagnostics.fish,
			--  https://www.typescriptlang.org/docs/handbook/compiler-options.html
			--  Parses diagnostics from the TypeScript compiler.
			require'null-ls'.builtins.diagnostics.tsc,
			--  https://fishshell.com/docs/current/cmds/fish_indent.html
			--  Indent or otherwise prettify a piece of fish code.
			require'null-ls'.builtins.formatting.fish_indent,
			--  https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#printenv
			--  Shows the value for the current environment variable under the cursor.
			require'null-ls'.builtins.hover.printenv,
		}
	}
	require'mason-lspconfig'.setup{
        automatic_installation = true,
		ensure_installed = {
			"eslint",
			"html",
			"jsonls",
			"tsserver",
			-- This is sumneko_lua. Not my favorite.
			-- TODO needs to know the root dir for nvim/init.lua (the neovim config file)
			--  INFO this only fails when the first buffer is the neovim config file. Other times it's on single-file mode.
			--   INFO this can be short-term fixed by running :LspStart lua_ls when editing this file
			"lua_ls",
			"ruff_lsp", -- Super fast python linting & etc.
			"pyright", -- Everything else python LSP
			"rust_analyzer",
			"svelte",
			"taplo", -- For TOML
			"vimls",
		},
		handlers = {
			function (server_name) -- default handler (optional)
				require'lspconfig'[server_name].setup(default_args)
			end,
			--["rust_analyzer"] = function ()
			--	require("rust-tools").setup {}
			--end
			ruff_lsp = function ()
				require'lspconfig'.ruff_lsp.setup {
					on_attach = default_args.on_attach,
					capabilities = vim.tbl_extend('keep', capabilities, {
						-- Pyright does it better
						hoverProvider = false
					})
				}
			end
		}
	}
end

local function configure_lualine()
	--                                   █ 🙽 🙼 🙿   🙾
	-- TODO local prepend_ln = function(str)
	-- 	return " " .. str
	-- end
	local function lightline_visual_selection()
		local mode = vim.fn.mode()
		local lines = vim.fn.abs(vim.fn.line("v") - vim.fn.line(".")) + 1
		local lines_str = '↕' .. lines
		local cols = vim.fn.abs(vim.fn.col("v") - vim.fn.col(".")) + 1
		local cols_str = '↔' .. cols
		if mode == 'v' or mode == 's' then
			if lines == 1 then
				return cols_str
			else
				return lines_str
			end
		elseif mode == 'V' or mode == 'S' then
			return lines_str
		elseif mode == '' then
			return lines_str .. ' ' .. cols_str
		else
			return ''
		end
	end
	require'lualine'.setup{
		options = {
			-- Don't be fooled. Nice theme, but not using base16 at all.
			-- This has became a problem. My phone's shell doesn't support truecolor.
			--theme = 'base16'
			theme = 'auto' -- Default theme
		},
		sections = {
			lualine_c = {
				'filename',
				lightline_visual_selection,
				require'lsp-status'.status,
				{
					require'lazy.status'.updates,
					cond = require'lazy.status'.has_updates
				}
			}
		}
		-- TODO extensions for integration
	}
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

	vim.o.tabstop = 4
	vim.o.shiftwidth = 4
	vim.o.backspace = 'indent,eol,start'

	-- Use sys clipboard
	vim.o.clipboard = 'unnamedplus'
	-- TODO install `lemonade` or `doitclient` to get SSH clipboard. termux or tmux perhaps, but likely not.

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
end

local lazy_config = { defaults = { lazy = true } }

local lazy_plugins = {
	-- Commenting
	--Plug 'tpope/vim-commentary'
	-- The looks of Powerline but faster than:
	-- - Powerline
	-- - Airline
	-- - And the well-known, formerly first-place Lightline
	{ 'nvim-lualine/lualine.nvim', config = configure_lualine, lazy = false },
	--[[{
		'kdheepak/tabline.nvim',
		-- disable = true, -- TODO Buggy: Tabs are per window when windows should be per tab.
		config = function ()
			require'tabline'.setup {
				options = {
					show_tabs_only = true,
				}
			}
		end
	},]]
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
		-- TODO not maintained
		'thaerkh/vim-indentguides',
		config = function ()
			vim.g.indentguides_spacechar = '⍿'
			vim.g.indentguides_tabchar = '⟼'
			vim.g.indentguides_concealcursor_unaltered = 'nonempty value'
			--|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
			--|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
		end,
		event = "BufEnter"
	},
	-- Super fancy coloring
	{ 'nvim-treesitter/nvim-treesitter', opts = {}, build = ':TSUpdate', event = 'VeryLazy' },
	{
		-- TODO pick better one
		'RRethy/nvim-base16',
		config = function ()
			vim.cmd.colorscheme'base16-default-dark'
			if false then -- I'm still working this out. Contrast issues right now.
				vim.api.nvim_create_autocmd("BufEnter", {
					pattern = "*",
					callback = function()
						local hl = vim.api.nvim_get_hl_by_name("Normal", "")
						hl.background = "NONE"
						vim.api.nvim_set_hl(0, "Normal", hl)
						print("fixed bg!")
					end
				})
			end
		end,
		lazy = false
	},

	-- Git integration
	--  Genral use
	{ 'tpope/vim-fugitive', event = "VeryLazy" },
	--  Line-per-line indicators and chunk selection
	{ 'airblade/vim-gitgutter', event = "BufEnter" }, -- TODO gitsigns
	-- Nicer file management TODO very slow. loads of *tree* replacements
	--   Can be replaced with (in no particular order, not including everything)
	--   - nvim-neo-tree/neo-tree.nvim
	--   - nvim-tree/nvim-tree.lua
	--   - nvim-treesitter/nvim-treesitter
	--   - Xuyuanp/yanil
	--   - vimfiler
	'preservim/nerdtree',
	{ 'tiagofumo/vim-nerdtree-syntax-highlight', lazy = false, dependencies = 'nerdtree' },
	--Plug 'jistr/vim-nerdtree-tabs'
	{ 'Xuyuanp/nerdtree-git-plugin', dependencies = 'nerdtree' }, -- TODO not maintained

	-- Icons
	--   TODO find alternative that adds the icons to each of these dependencies
	{ 'ryanoasis/vim-devicons', dependencies = { 'nerdtree', 'vim-startify', 'nerdtree-git-plugin' }, lazy = false },
	--  An incompatible fork of the above.
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
		event = "VeryLazy"
	},
	--  Start Screen
	'mhinz/vim-startify',
	-- common dependencie of many nvim plugins
	'nvim-lua/plenary.nvim',
	{ 'jose-elias-alvarez/null-ls.nvim', event = "VeryLazy" },
	{ 'jay-babu/mason-null-ls.nvim', event = "VeryLazy" },
	-- Interactive eval
	-- use 'Olical/conjure' -- TODO configure this -- this might be a problem 987632498629765296987492

	-- Specific file type compat
	--  General stuff (syntax, etc)
	{ 'sheerun/vim-polyglot', event = "BufEnter" },
	--  Eww's configuration language, yuck
	{ 'elkowar/yuck.vim', event = "BufEnter" },
	--  Support editorconfig files
	--   TODO configure
	--'editorconfig/editorconfig-vim',
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
			'mason-null-ls.nvim'
		},
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
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
					--  Pre-configured snippits
					'rafamadriz/friendly-snippets'
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
				-- Fish completion
				'mtoohey31/cmp-fish',
				-- Use LSP symbols for buffer-style search
				'hrsh7th/cmp-nvim-lsp-document-symbol',
				-- Completion on the vim.lsp apis
				'hrsh7th/cmp-nvim-lua',
				-- Use /usr/share/dict/words for completion
				{ 'uga-rosa/cmp-dictionary', opts = { dic = { ["*"] = "/usr/share/dict/words" } } }
			}
		}
	},
	-- crates.io completion source
	{ 'saecki/crates.nvim', opts = {}, event = "BufRead Cargo.toml" },
	-- package.json completion source
	{ 'David-Kunz/cmp-npm', opts = {}, event = "BufRead package.json" },
	-- conjure intractive eval completion
	--use 'PaterJason/cmp-conjure' -- TODO add this to cmp -- this might be a problem 987632498629765296987492
}
require("lazy").setup(lazy_plugins, lazy_config)
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
