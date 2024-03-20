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
	--[[local function has_words_before()

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
		if check_cmd then
			local read_res = check_cmd:read"*all"
			local val = ({check_cmd:close()})[3]
			local it_has_it = #read_res > 0
			theCommandsThatWeKnow[tim] = it_has_it
			return it_has_it
		else
			theCommandsThatWeKnow[tim] = false
			return false
		end
	end
end

-- only load things if npm, pnpm or yarn is present
-- TODO: consider checking for npm, pnpm and  yarn.
-- TODO: consider just checking for node
local function has_npm()
	return has_the_command_that_some_call"npm"
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

-- TODO: Ignore duplicate keys for this table (only)
--
-- Hooks for everything around the lspconfig function
--     Heh. Remember back when I thought it was only going to do lspconfig? Yeah, me neither.
local setup_configure_lspconfig = {
	lsp_on_attach = function () end,
	make_capabilities = function ()
		return vim.lsp.protocol.make_client_capabilities()
	end,
	manual_lspconfigs = function () end
}

do
	local lsp_on_attach = setup_configure_lspconfig.lsp_on_attach
	setup_configure_lspconfig.lsp_on_attach = function (client, bufnr, ...)
		lsp_on_attach(client, bufnr, ...)
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
		vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts) -- TODO: broken???
		vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
		vim.keymap.set('n', '<space>f', function()
			vim.lsp.buf.format { async = true }
		end, bufopts)
	end
end

do
	local manual_lspconfigs = setup_configure_lspconfig.manual_lspconfigs
	setup_configure_lspconfig.manual_lspconfigs = function (lspconfig, default_args)
		manual_lspconfigs(lspconfig, default_args)
		lspconfig.racket_langserver.setup(default_args)
	end
end
do
	local manual_lspconfigs = setup_configure_lspconfig.manual_lspconfigs
	setup_configure_lspconfig.manual_lspconfigs = function (lspconfig, default_args)
		manual_lspconfigs(lspconfig, default_args)
		lspconfig.clangd.setup{
			on_attach = default_args.on_attach,
			capabilities = vim.tbl_extend('keep', default_args.capabilities, {
				handlers = require'lsp-status'.extensions.clangd.setup(),
				init_options = { clangdFileStatus = true }
			})
		}
	end
end

local get_lsp_default_args

local function configuire_lspconfig()
	local default_args={
		on_attach = setup_configure_lspconfig.lsp_on_attach,
		capabilities = setup_configure_lspconfig.make_capabilities()
	}
	setup_configure_lspconfig.lsp_on_attach = nil
	setup_configure_lspconfig.make_capabilities = nil
	get_lsp_default_args = function ()
		return default_args
	end
	local capabilities = default_args.capabilities
	-- Installed manually in system.
	setup_configure_lspconfig.manual_lspconfigs(require'lspconfig', default_args)
	setup_configure_lspconfig.manual_lspconfigs = nil
	-- Installed through mason
	require'mason'.setup{
		max_concurrent_installers = require'luv'.available_parallelism(),
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗"
			}
		}
	}
	-- TODO: assert that all requirements in `:h mason-requirements` are met
	-- Style rule: All sources _must_ link to the documentation for each source.
	-- Must also include what it does.
	-- https://github.com/nvimdev/guard.nvim -- Linter chains (for if efm doesn't work)
	local mason_tool_installed = {
		'rustfmt', -- WARNING: reccomends rustup instead of whatever it's doing now (deprecation)
		'luacheck', -- TODO: what does this require
		-- TODO: requires unzip
		--'selene',
		'stylua', -- TODO: what does this require
		-- TODO: requires cargo
		'shellharden',
		-- For Java
		--'vscode-java-decompiler', -- TODO: This should be done from the DAP side of things, if possible
		"checkstyle"
	}
	local mason_tool_installed_npm = {
		"stylelint", "prettier",
	}
	if has_npm() then
		for _, name in ipairs(mason_tool_installed_npm) do
			mason_tool_installed[#mason_tool_installed+1] = name
		end
	end
	require'mason-tool-installer'.setup{ ensure_installed = mason_tool_installed }
	local function efm ()
		local function efm_formatter(name)
			return require("efmls-configs.formatters." .. name)
		end
		local function efm_linter(name)
			return require("efmls-configs.linters." .. name)
		end
		local prettier = efm_formatter"prettier"
		local css = { efm_linter"stylelint", prettier }
		local prettier_only = { prettier } -- eslint isn't needed - we have the lsp
		local languages = {
			css = css, less = css, scss = css, sass = css,
			javascript = prettier_only, javascriptreact = prettier_only,
			typescript = prettier_only, typescriptreact = prettier_only,
			html = prettier_only,
			lua = { efm_linter"luacheck", efm_formatter"stylua"--[[, efm_linter"selene"]] },
			vim = { efm_linter"vint" }, -- TODO: what does this require
			rust = { efm_formatter"rustfmt" },
			sh = { efm_formatter"shellharden" },
			fish = { efm_linter"fish", efm_formatter"fish_indent" }
		}
		local filetypes = {}
		for lang, _ in pairs(languages) do
			filetypes[#filetypes+1] = lang
		end
		require'lspconfig'.efm.setup{
			on_attach = default_args.on_attach,
			capabilities = capabilities,
			settings = {
				-- TODO: can this be used elsewhere (like lua_ls)?
				rootMarkers = {".git/"},
				languages = languages
			},
			filetypes = filetypes
		}
	end
	local lsp_installed = {
		-- This is sumneko_lua. Not my favorite.
		-- TODO: needs to know the root dir only fails to find it on it's own when the first buffer is a lua file.
		--  Not related to rooter
		-- can be short-term fixed by running :LspStart lua_ls when editing this file
		-- This happens to efm as well. Might be happening to everything if that's the first file.
		"lua_ls",
		"ruff_lsp", -- Super fast python linting & etc.
		"rust_analyzer",
		"taplo", -- For TOML
		"marksman", -- For markdown
		"efm",
		-- For Java
		"jdtls"
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
	if has_npm() then
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
				function () return require'lsp-status'.status() end,
				-- The below doesn't look good and provides nothing I need
				--function () -- NOTE: this would also need to only load if treesitter is installed (in the system)
				--	return vim.fn['nvim_treesitter#statusline']{indicator_size=20}
				--end
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
	vim.diagnostic.config{ severity_sort = true, virtual_text = { prefix = function(diagnostic, _, _)
		local severity = diagnostic.severity
		if type(severity) == "table" then
			severity = severity.min or severity[1]
		end

		local ERROR = vim.diagnostic.severity.ERROR
		local WARN = vim.diagnostic.severity.WARN
		local INFO = vim.diagnostic.severity.INFO
		local HINT = vim.diagnostic.severity.HINT

		-- Here we are getting the icons from the lualine default settings. If you change lualine's config, these icons will
		-- not change with it.
		-- TODO: deal with possible API changes?
		local icons = require"lualine.components.diagnostics.config".symbols.icons

		if severity == ERROR then
			return icons.error
		elseif severity == WARN then
			return icons.warn
		elseif severity == INFO then
			return icons.info
		elseif severity == HINT then
			return icons.hint
		end
	end } }

	-- see the docstrings for folded code
	-- TODO: this looks typo-ed and is likely broken
	vim.g.SimpylFold_docstring_preview = 1

	--vim.keymap.set('n', '<Leader>d', vim.diagnostic.goto_next)

	-- TODO: unless there's a conflict, learn the _actual_ shortcuts (and remove these)

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
end

local lazy_config = { defaults = { lazy = true }, checker = { enabled = true, notify = false } }

local lazy_plugins = {
	-- Commenting
	--Plug 'tpope/vim-commentary'
	-- The looks of Powerline but faster than:
	-- - Powerline
	-- - Airline
	-- - And the well-known, formerly first-place Lightline
	{
		'nvim-lualine/lualine.nvim',
		config = configure_lualine,
		event = "BufEnter",
		dependencies = 'nvim-lua/lsp-status.nvim'
	},
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
		event = "VeryLazy", -- TODO: better lazyness?
		main = "ibl",
		--version = "^3.3",
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
	{
		-- TODO: only load this if tree-sitter is installed
		'nvim-treesitter/nvim-treesitter',
		--opts = ,
		dependencies = {
			-- A companion to windwp/nvim-autopairs that does xml
			"windwp/nvim-ts-autotag",
			event = "InsertEnter",
			opts = { enabled = true }
		},
		config = function ()
			require'nvim-treesitter.configs'.setup{
				sync_install = true,
				auto_install = true -- With this, I don't actually need any list. It lazy-installs this way.
			}
		end,
		build = ':TSUpdateSync',
		event = 'VeryLazy' -- TODO: better lazyness?
	},
	{
		-- TODO: (low prio) match this and the cmd theme
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
		--branch = "v3.x",
		branch = "main",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
		config = function ()
			vim.g.neo_tree_remove_legacy_commands = 1
			vim.g.loaded_netrwPlugin = 1 -- Don't load both this and the builtin tree
			require'neo-tree'.setup{ window = { position = "current" } }
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
	-- un-recursor
	{
		"samjwill/nvim-unception",
		init = function()
			vim.g.unception_block_while_host_edits = 1
		end,
		lazy = false
	},
	{
		'airblade/vim-rooter',
		config = function ()
			vim.g.rooter_change_directory_for_non_project_files = 'current'
			-- vim.g.rooter_patterns = ['.git', 'mod.conf', 'modpack.conf','game.conf','texture_pack.conf']
		end,
		lazy = false,
		cond = function ()
			-- dont load if we are in neovimpager
			return not inside_neovimpager()
		end
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
		dependencies = { 'WhoIsSethDaniel/mason-tool-installer.nvim', event = "VeryLazy" }, -- Install the linters -- TODO: better lazyness?
		event = "VeryLazy" -- TODO: better lazyness?
	},
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
	{
		-- TODO: is it possible to replace this with something that uses treesitter or LSP?
		"folke/todo-comments.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		opts = {
			keywords = {
				-- matches the word, so break it on purpose
				FIX = { icon = "" },
				TODO = { icon = "" },
				HACK = { icon = "" },
				WARN = { icon = "" },
				TEST = { icon = "" },
				PERF = { icon = "󰓅" },
				NOTE = { icon = "󱇗" }
			},
			-- Allow omitting the semicolon
			---- vim regex
			--highlight = { after = "", pattern = [[.*<(KEYWORDS)\s*:?]] },
			---- ripgrep regex
			--search = { pattern = [[\b(KEYWORDS):?]] }, -- TODO: false positives. it it big enough of a problem? Fixable?
		},
		event = "VeryLazy" -- TODO: better lazyness?
	},

	-- Language-server protocol
	-- Must be after language specific things
	{
		'neovim/nvim-lspconfig',
		config = configuire_lspconfig,
		module = {
			'lspconfig',
			"mason.nvim",
			'mason-lspconfig.nvim',
		},
		dependencies = {
			'creativenull/efmls-configs-nvim',
			'cmp-nvim-lsp'
		},
		event = "VeryLazy" -- TODO: better lazyness?
	},
	{
		'nvim-lua/lsp-status.nvim',
		config = function()
			local lsp_status = require'lsp-status'
			lsp_status.config{
				status_symbol = '', -- The default V breaks some layout stuff.  was the next I used, but it's not needed
				show_filename = false, -- Takes up too much space, redundant
				diagnostics = false, -- lualine actually already displays this information
				kind_labels = require'lspkind'.symbol_map,
			}
			lsp_status.register_progress()
			local lsp_on_attach = setup_configure_lspconfig.lsp_on_attach
			setup_configure_lspconfig.lsp_on_attach = function (...)
				lsp_on_attach(...)
				lsp_status.on_attach(...)
			end
			local make_capabilities = setup_configure_lspconfig.make_capabilities
			setup_configure_lspconfig.make_capabilities = function ()
				local capabilities = make_capabilities()
				capabilities = vim.tbl_extend('keep', capabilities, require'lsp-status'.capabilities)
				return capabilities
			end
		end,
		module = 'lsp-status'
	},
	-- Automate installing some language-servers
	{ 'williamboman/mason.nvim', event = "VeryLazy" }, -- TODO: better lazyness?
	{ 'williamboman/mason-lspconfig.nvim', event = "VeryLazy" }, -- TODO: better lazyness?
	-- Update command for mason
	--  https://github.com/RubixDev/mason-update-all#updating-from-cli
	{ 'RubixDev/mason-update-all', opts = {}, event = "BufEnter" },
	-- Better folding
	{
		'pierreglaser/folding-nvim',
		config = function()
			local lsp_on_attach = setup_configure_lspconfig.lsp_on_attach
			setup_configure_lspconfig.lsp_on_attach = function (...)
				lsp_on_attach(...)
				require'folding'.on_attach(...)
			end
		end
	},

	-- Completion details (uses LSP)
	{
		'hrsh7th/cmp-nvim-lsp',
		dependencies = {
			'hrsh7th/nvim-cmp',
			config = configure_nvim_cmp,
			dependencies  = {
				{
					'saadparwaiz1/cmp_luasnip',
					-- Snippet source. (There's others out there too)
					dependencies = {{
						'L3MON4D3/LuaSnip',
						config = function ()
							-- Grab things from rafamadriz/friendly-snippets & etc.
							require"luasnip.loaders.from_vscode".lazy_load()
						end,
						--  Pre-configured snippits
						dependencies = 'rafamadriz/friendly-snippets'
					}},
				},
				-- Lower the text sorting of completions starting with _
				'lukas-reineke/cmp-under-comparator',
				-- Use /usr/share/dict/words for completion
				{
					'uga-rosa/cmp-dictionary',
					enabled = false,
					config = function ()
						local dict = require"cmp_dictionary"
						dict.setup{ debug = true }
						dict.switcher{ spelling = { en = "/usr/share/dict/words" } }
					end
				}
			}
		},
		config = function ()
			local cmp_nvim_lsp = require'cmp_nvim_lsp'
			local lsp_on_attach = setup_configure_lspconfig.lsp_on_attach
			setup_configure_lspconfig.lsp_on_attach = function (...)
				lsp_on_attach(...)
				--require'cmp'.setup.buffer{sources={ { name = 'nvim_lsp' } }}
				-- BUG: doesn't seem to trigger on its own. I have to do this for now.
				cmp_nvim_lsp._on_insert_enter()
			end
			local make_capabilities = setup_configure_lspconfig.make_capabilities
			setup_configure_lspconfig.make_capabilities = function ()
				local capabilities = make_capabilities()
				capabilities = vim.tbl_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
				return capabilities
			end
		end
	},
	-- cmdline history completion
	{
		'dmitmel/cmp-cmdline-history',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp',
		enabled = false
	},
	-- Completion within this buffer
	{
		'hrsh7th/cmp-buffer',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- Completion on the vim.lsp apis
	{
		'hrsh7th/cmp-nvim-lua',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- Path completion
	{
		'hrsh7th/cmp-path',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp'
	},
	-- VI : command completion
	{
		'hrsh7th/cmp-cmdline',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp',
	},
	-- Use LSP symbols for buffer-style search
	{
		'hrsh7th/cmp-nvim-lsp-document-symbol',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = { 'hrsh7th/cmp-nvim-lsp', 'nvim-cmp' }
	},
	-- Git completion source
	{
		'petertriho/cmp-git',
		event = "VeryLazy", -- TODO: better lazyness?
		dependencies = 'nvim-cmp',
		config = function ()
			require'cmp_git'.setup{}
			-- TODO: this is per-buffer
			--require'cmp'.setup.buffer{ sources = { { name = "git" } } }
		end
	},
	-- crates.io completion source
	{
		'saecki/crates.nvim',
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
	{
		'David-Kunz/cmp-npm',
		dependencies = { 'plenary.nvim', 'nvim-cmp' },
		event = "BufRead package.json",
		cond = function  ()
			return has_npm()
		end,
		config = function ()
			require'cmp-npm'.setup{}
			-- TODO: this is per-buffer
			--require'cmp'.setup.buffer{ sources = { { name = 'npm', keyword_length = 4 } } }
		end
	},
	-- Fish completion
	{
		'mtoohey31/cmp-fish',
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
	{
		'kdheepak/cmp-latex-symbols',
		event = "VeryLazy", -- TODO: better lazyness?
	},
	-- Emoji completion support
	{
		'hrsh7th/cmp-emoji',
		event = "VeryLazy", -- TODO: better lazyness?
	},
	-- conjure intractive eval completion
	--use 'PaterJason/cmp-conjure' -- TODO: add this to cmp -- this might be a problem 987632498629765296987492
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
		--event = 'BufEnter',
		event = "VeryLazy", -- TODO: better lazyness?
		config = function ()
			local installed = {
				"js", "bash", "node2", "chrome", "cppdbg", "mock", "puppet", "python", "codelldb",
				-- For Java
				"javadbg", "javatest"
			}
			if has_npm() then
				installed[#installed+1] = "firefox"
			end
			require'mason-nvim-dap'.setup{
				ensure_installed = installed,
				automatic_installation = true,
				handlers = {}
			}
		end
	},
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
	{
		-- Place pairs after typing, ex { causes } to appear.
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			fast_wrap = {
				map = '<M-r>' -- <M-e> is to open the default GUI explorer in my WM
			}
		}
	},
}
require("lazy").setup(lazy_plugins, lazy_config)
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
