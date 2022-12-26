local vim = vim -- Hacky workaround for sumneko_lua being sorta dumb right now. I can fix it better later.
-- This new bootstrapping code was copied from https://github.com/wbthomason/packer.nvim#bootstrapping
local function ensure_packer()
	local fn = vim.fn
	local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system{'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path}
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

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

local function configure_cmp_dictionary()
	require"cmp_dictionary".setup{dic = {["*"] = "/usr/share/dict/words"}}
end

local function configure_nvim_cmp()
	local cmp = require'cmp'
	local lspkind = require'lspkind'
	local cmp_under_comparator = require"cmp-under-comparator"
	local luasnip = require'luasnip'
	local function has_words_before()
		-- TODO use this approch for line & col elsewhere
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
	end
	cmp.setup{
		--Defaults:https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
		snippet = {
			expand = function(args)
				luasnip.lsp_expand(args.body)
			end,
		},
		mapping = {
			-- TODO Can't use `cmp.scroll_docs` alias. Must go through mapping first.
			-- TODO same for these:
			-- - `cmp.complete`
			-- - `cmp.select_next_item`
			-- - `cmp.select_prev_item`
			-- - `cmp.abort`
			-- - `cmp.close`
			['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
			['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
			['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
			['<C-e>'] = cmp.mapping{
				i = cmp.mapping.abort(),
				c = cmp.mapping.close(),
			},
			['<Tab>'] = cmp.mapping.confirm{ select = true },
			-- TODO better (non race condition) way of doing the tabs. (see the other
			--  place below that luasnip is used in the context of a keymap
			-- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#luasnip
			--[[['<Tab>'] = cmp.mapping(function (fallback)
				if cmp.visible() then
					print"tabbed! cmp visible"
					--cmp.mapping.select_next_item()
					cmp.mapping.confirm{ select = true }
				elseif luasnip.expand_or_jumpable() then
					print"tabbed! luasnip expand or jumpable"
					luasnip.expand_or_jump()
				elseif has_words_before() then
					print"tabbed! has words before"
					cmp.mapping.complete()
				else
					print"tabbed! fallback"
					fallback()
				end
			end, { 'i', 's' }),
			['<S-Tab>'] = cmp.mapping(function (fallback)
				if cmp.visible() then
					cmp.mapping.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { 'i', 's' }),]]
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
			{
				name = "dictionary",
				keyword_length = 2,
			},
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
				cmp_under_comparator.under,
				cmp.config.compare.kind,
				cmp.config.compare.sort_text,
				cmp.config.compare.length,
				cmp.config.compare.order,
			},
		},
		formatting = {
			format = lspkind.cmp_format{
				with_text = true,
				--[[
				symbol_map = {
					-- Also effects anything else using lspkind
					Constructor = '🏗 ',
					Variable = lspkind.presets.default.Field,
					File = '🗎',
					Unit = '🞕',
					Reference = '►',
					Constant = 'π',
					Struct = 'ﱖ',
				},]]
				menu = {
					buffer                   = "[Buffer]",
					nvim_lsp                 = "[LSP]",
					nvim_lua                 = "[Lua]",
					latex_symbols            = "[Latex]",
					luasnip                  = "[LuaSnip]",
					emoji                    = "[Emoji]",
					git                      = "[Git]",
					crates                   = "[Crates]",
					npm                      = "[NPM]",
					pandoc_references        = "[Pandoc]",
					fish                     = "[Fish]",
					path                     = "[Path]",
					cmdline_history          = "[CmdHistory]",
					cmdline                  = "[Cmd]",
					nvim_lsp_document_symbol = "[LSPSymbol]",
					dictionary               = "[Dict]",
				}
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
	local lspkind = require'lspkind'
	lsp_status.config{
		status_symbol = '', -- The default V breaks some layout stuff.  was the next I used, but it's not needed
		show_filename = false, -- Takes up too much space, redundant
		diagnostics = false, -- lualine actually already displays this information
		kind_labels = lspkind.symbol_map,
	}
	lsp_status.register_progress()
end

-- see https://github.com/wbthomason/packer.nvim/issues/1090
--local function configuire_lspconfig()
local configuire_lspconfig = [[
	local lspconfig=require'lspconfig'
	local lsp_status = require'lsp-status'
	local cmp_nvim_lsp = require'cmp_nvim_lsp'
	local nvim_lsp_installer = require"nvim-lsp-installer"
	local folding = require'folding'
	local default_args={
		on_attach = function(...)
			lsp_status.on_attach(...)
			folding.on_attach(...)
		end,
	}
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = vim.tbl_extend('keep', capabilities, lsp_status.capabilities)
	capabilities = vim.tbl_extend('keep', capabilities, cmp_nvim_lsp.default_capabilities())
	default_args.capabilities = capabilities
	nvim_lsp_installer.on_server_ready(function(server)
		local options = default_args
		-- (optional) Customize the options passed to the server
		if server.name == "pyls_ms" then
			options = vim.tbl_extend('keep',default_args,{
				-- lsp_status supports some extensions
				handlers = lsp_status.extensions.pyls_ms.setup(),
				settings = { python = { workspaceSymbols = { enabled = true }}},
			})
		end
		-- This setup() function is exactly the same as lspconfig's setup function.
		-- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
		server:setup(options)
	end)
	-- Confirmed to have been used
	lspconfig.racket_langserver.setup(default_args)
	lspconfig.clangd.setup(
		default_args,
		vim.tbl_extend('keep',default_args,{
			-- lsp_status supports some extensions
			handlers = lsp_status.extensions.clangd.setup(),
			init_options = {
				clangdFileStatus = true
			}
		})
	)
]]
--end

local function configure_null_ls()
	local null_ls = require"null-ls"
	local builtins = null_ls.builtins
	local code_actions = builtins.code_actions
	local diagnostics = builtins.diagnostics
	local formatting = builtins.formatting
	local hover = builtins.hover
	null_ls.setup{
		-- TODO do this dynamicly
		sources = {
			-- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
			-- Style rule: All sources _must_ link to the documentation for each source.
			-- Must also include what it does.
			--  https://github.com/streetsidesoftware/cspell
			--  Injects actions to fix typos found by `cspell`.
			diagnostics.cspell, code_actions.cspell,
			--TODO cspell needs to be installed
			--  https://github.com/mantoni/eslint_d.js
			--  Injects actions to fix ESLint issues or ignore broken rules. Like ESLint, but faster.
			--   There's an XO specific one too.
			--   Beware that eslint_d remains running in the background.
			code_actions.eslint_d, diagnostics.eslint_d,
			--  https://github.com/lewis6991/gitsigns.nvim
			--  Injects code actions for Git operations at the current cursor position
			--   (stage / preview / reset hunks, blame, etc.).
			--   TODO gutter highlights are broken.
			--code_actions.gitsigns,
			-- TODO ltrs or proselint both look cool. Documentation Grammar
			-- TODO refactoring is usefull
			-- TODO luasnip (simpler config?)

			--  https://github.com/get-alex/alex
			--  Catch insensitive, inconsiderate writing.
			diagnostics.alex,
			--  https://github.com/dotenv-linter/dotenv-linter
			--  Lightning-fast linter for .env files.
			diagnostics.dotenv_linter,
			--  https://github.com/editorconfig-checker/editorconfig-checker
			--  A tool to verify that your files are in harmony with your `.editorconfig`.
			diagnostics.editorconfig_checker,
			--  https://github.com/fish-shell/fish-shell
			--  Basic linting is available for fish scripts using `fish --no-execute`.
			diagnostics.fish,
			--  https://github.com/charliermarsh/ruff/
			--  An extremely fast Python linter, written in Rust.
			diagnostics.ruff,
			--  https://kampfkarren.github.io/selene/
			--  Command line tool designed to help write correct and idiomatic Lua code.
			diagnostics.selene,
			--  https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#todo_comments
			--  Uses inbuilt Lua code and treesitter to detect lines with TODO comments and show a diagnostic warning on each
			--   line where it's present.
			diagnostics.todo_comments,
			--  https://www.typescriptlang.org/docs/handbook/compiler-options.html
			--  Parses diagnostics from the TypeScript compiler.
			diagnostics.tsc,
			--  https://github.com/Vimjas/vint
			--  Linter for Vimscript.
			diagnostics.vint,
			--  https://fishshell.com/docs/current/cmds/fish_indent.html
			--  Indent or otherwise prettify a piece of fish code.
			formatting.fish_indent,
			--  https://github.com/rust-lang/rustfmt
			--  A tool for formatting rust code according to style guidelines.
			formatting.rustfmt,
			--  https://github.com/anordal/shellharden
			--  Hardens shell scripts by quoting variables, replacing `function_call` with `$(function_call)`, and more.
			formatting.shellharden,
			--  https://github.com/JohnnyMorganz/StyLua
			--  An opinionated code formatter for Lua.
			formatting.stylua,
			--  https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#printenv
			--  Shows the value for the current environment variable under the cursor.
			hover.printenv,
		}
	}
end

local function configure_tabline()
	require'tabline'.setup {
		options = {
			show_tabs_only = true,
		}
	}
end

-- See https://github.com/wbthomason/packer.nvim/issues/1090
--local function configure_lualine()
local configure_lualine = [[
	--                                   █ 🙽 🙼 🙿   🙾
	-- TODO replace mode
	-- TODO local prepend_ln = function(str)
	-- 	return " " .. str
	-- end
	local lsp_status = require'lsp-status'
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
			-- TODO This has become a problem. My phone's shell doesn't support truecolor.
			theme = 'base16'
		},
		sections = {
			lualine_c = {
				'filename',
				lightline_visual_selection,
				function()
					-- TODO because of https://github.com/wbthomason/packer.nvim/issues/1090
					-- we can't get the exact components we wish the way we want to using vim.g.lsp_function_name
					return lsp_status.status()
				end
			}
		}
	}
]]
--end

local packer_bootstrap = ensure_packer()

local packer_config = {
	profile = {
		enable = true,
		-- Amount of load time for plugin to be included in profile
		threshold = 0,
	}
}

return require'packer'.startup{function(use)
	use 'wbthomason/packer.nvim' -- Self-manage the package manager.

	-- Commenting
	--Plug 'tpope/vim-commentary'
	-- The looks of Powerline but faster than:
	-- - Powerline
	-- - Airline
	-- - And the well-known, formerly first-place Lightline
	use {
		'nvim-lualine/lualine.nvim',
		config = configure_lualine,
		requires = 'nvim-web-devicons',
		after = 'nvim-base16'
	}
	use {
		'kdheepak/tabline.nvim',
		config = configure_tabline,
		requires = {'lualine.nvim','nvim-web-devicons'}
	}
	-- The looks of Powerline, but faster
	use{
		'itchyny/lightline.vim',
		disable = true,
		--config = configure_lightline,
		requires = {
			'vim-fugitive',
			'lsp-status.nvim'
		}
	}
	-- Indent lines
	use{
		'thaerkh/vim-indentguides',
		-- see https://github.com/wbthomason/packer.nvim/issues/1090
		config = [[
			vim.g.indentguides_spacechar = '⍿'
			vim.g.indentguides_tabchar = '⟼'
			vim.g.indentguides_concealcursor_unaltered = 'nonempty value'
			--|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
			--|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
		]]
	}
	-- Super fancy coloring
	use {
		'RRethy/nvim-base16',
		-- see https://github.com/wbthomason/packer.nvim/issues/1090
		config = [[
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
		]]
	}

	-- Git integration
	--  Genral use
	use 'tpope/vim-fugitive'
	--  Line-per-line indicators and chunk selection
	use 'airblade/vim-gitgutter' -- TODO gitsigns
	-- Nicer file management
	use 'preservim/nerdtree'
	use 'tiagofumo/vim-nerdtree-syntax-highlight'
	--Plug 'jistr/vim-nerdtree-tabs'
	use 'Xuyuanp/nerdtree-git-plugin'

	-- Icons
	use 'ryanoasis/vim-devicons'
	use 'kyazdani42/nvim-web-devicons'
	--  LSP breakdown icons and stuff
	use 'onsails/lspkind-nvim'

	--  This should work on all files (it's python support ain't great)
	--Plug 'khzaw/vim-conceal'
	--Plug 'jamestomasino-forks/vim-conceal' " This one has better javascript support
	--Plug 'Lazerbeak12345/vim-conceal' " This is my blend of a bunch of stuff (my
	--    fork of above)
	-- Ease of use
	use 'vimlab/split-term.vim'
	use {
		'airblade/vim-rooter',
		-- see https://github.com/wbthomason/packer.nvim/issues/1090
		config = [[
			vim.g.rooter_change_directory_for_non_project_files = 'current'
			-- vim.g.rooter_patterns = ['.git', 'mod.conf', 'modpack.conf','game.conf','texture_pack.conf']
		]]
	}
	--  Start Screen
	use 'mhinz/vim-startify'
	-- common dependancies of many nvim plugins
	use 'nvim-lua/plenary.nvim'
	use {
		'jose-elias-alvarez/null-ls.nvim',
		--disable = true, -- TODO figure out how to make actual use of this
		config = configure_null_ls,
		requires = "plenary.nvim",
		--after = 'neovim/nvim-lspconfig',
	}
	-- Interactive eval
	use 'Olical/conjure' -- TODO configure this

	-- Specific file type compat
	--  General stuff
	use 'sheerun/vim-polyglot'
	--  Eww's configuration language, yuck
	use 'elkowar/yuck.vim'
	--  Support editorconfig files
	--   TODO configure
	use 'editorconfig/editorconfig-vim'

	-- Language-server protocol
	-- Must be after language specific things
	use{
		'neovim/nvim-lspconfig',
		config = configuire_lspconfig,
		-- The config function for this requires these to be present. It's a two way dependancy.
		requires = {
			'lsp-status.nvim',
			'folding-nvim',
			'cmp-nvim-lsp',
			'nvim-lsp-installer'
		},
		module = {
			'lspconfig',
			--'lsp-status',
			'cmp_nvim_lsp',
			"nvim-lsp-installer",
			'folding'
		}
	}
	use{
		'nvim-lua/lsp-status.nvim',
		config = configure_lsp_status,
		requires = 'lspkind-nvim',
		module = 'lsp-status'
	}
	--Automate installing some language-servers
	use 'williamboman/nvim-lsp-installer'
	-- Better folding
	use 'pierreglaser/folding-nvim'

	-- Completion details (uses LSP)
	use{
		'hrsh7th/cmp-nvim-lsp',
		requires = 'nvim-cmp'
	}
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/cmp-path'
	use{
		'hrsh7th/nvim-cmp',
		config = configure_nvim_cmp,
		requires = {
			'lspkind-nvim',
			'cmp-dictionary',
			'cmp-git',
			'crates.nvim',
			'cmp-npm',
			'LuaSnip'
		},
		module_pattern = ".*cmp.*"
	}
	-- Lower the text sorting of completions starting with _
	use 'lukas-reineke/cmp-under-comparator'
	-- cmdline source
	use 'hrsh7th/cmp-cmdline'
	-- Snippet source. (There's others out there too)
	use {
		'L3MON4D3/LuaSnip',
		config = function ()
			-- Grab things from rafamadriz/friendly-snippets & etc.
			require("luasnip.loaders.from_vscode").lazy_load()
		end
	}
	use 'saadparwaiz1/cmp_luasnip'
	--  Pre-configured snippits
	use 'rafamadriz/friendly-snippets'
	-- Git completion source
	use{
		'petertriho/cmp-git',
		config = function()
			require"cmp_git".setup()
		end,
		requires = "plenary.nvim",
		-- They don't even talk - this is just because I won't need cmp-git until
		-- after interacting with fugitive anyway
		after = 'vim-fugitive'
	}
	-- crates.io completion source
	use {
		'saecki/crates.nvim',
		config = function()
			require'crates'.setup()
		end,
		requires = {
			'plenary.nvim'
		},
		event = "BufRead Cargo.toml"
	}
	-- package.json completion source
	use {
		'David-Kunz/cmp-npm',
		requires = {
			'plenary.nvim'
		},
		config = function()
			require'cmp-npm'.setup{}
		end,
		event = "BufRead package.json"
	}
	-- latex symbol completion support (allows for inserting unicode)
	use 'kdheepak/cmp-latex-symbols'
	-- Emoji completion support
	use 'hrsh7th/cmp-emoji'
	-- Pandoc completion
	use 'jc-doyle/cmp-pandoc-references'
	-- cmdline history completion
	--Plug 'dmitmel/cmp-cmdline-history'
	-- Fish completion
	use 'mtoohey31/cmp-fish'
	-- conjure intractive eval completion
	use 'PaterJason/cmp-conjure' -- TODO add this to cmp
	-- Use LSP symbols for buffer-style search
	use 'hrsh7th/cmp-nvim-lsp-document-symbol'
	-- Completion on the vim.lsp apis
	use 'hrsh7th/cmp-nvim-lua'
	-- Use /usr/share/dict/words for completion
	use{
		'uga-rosa/cmp-dictionary',
		config = configure_cmp_dictionary,
		opt = true -- TODO load in later when cmp runs
	}

	-- refer to https://github.com/nanotee/nvim-lua-guide

	--vim.lsp.set_log_level("debug")

	-- Which syntaxes would you like to enable highlighting for in vim files?
	vim.g.vimsyn_embed = 'l'

	-- Inline diagnostic alerts
	vim.diagnostic.config{
		severity_sort = true,
		virtual_text = {
			prefix = '🛈'
		}
	}

	-- see the docstrings for folded code
	vim.g.SimpylFold_docstring_preview = 1

	local function t(str)
		return vim.api.nvim_replace_termcodes(str, true, true, true)
	end

	--TODO chance of race conditions. Also, I can't type tab anymore.
	vim.keymap.set('i', '<Tab>', function ()
		local luasnip = require'luasnip'
		return luasnip.expand_or_jumpable() and luasnip.expand_or_jump() or t'<Tab>'
	end)
	vim.keymap.set('i', '<S-Tab>', function ()
		local luasnip = require'luasnip'
		return luasnip.jumpable(-1) and luasnip.jump(-1) or t'<S-Tab>'
	end)

	vim.keymap.set('n', '<Leader>d', vim.diagnostic.goto_next)

	-- Enable folding with the spacebar
	vim.keymap.set('n', '<space>', 'za')

	-- Go back one file in current buffer
	vim.keymap.set('n', '<Leader><Leader>', '<c-^>')

	-- Map <Esc> to exit terminal-mode (stolen from nvim's :help terminal-input then modified for lua)
	vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

	-- Keyboard shortcut to open nerd tree via currently disabled mod
	--vim.keymap.set('', '<Leader>n', '<Plug>NERDTreeTabsToggle<CR>')

	-- Make it a tad easier to change the terminal back to a buffer
	vim.keymap.set('', '<Leader>]', '<C-\\><C-n>')

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

	-- Title magic.
	vim.o.title = true

	-- I don't like presssing more most of the time
	vim.o.more = false

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

	-- TODO broken
	-- Always underline the current line
	-- change cursor on insert mode. doesn't always work
	-- below two lines no longer work in konsole
	--vim.o.t_SI = "\\e[3 q" -- insert
	--vim.o.t_EI = "\\e[1 q" -- command

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
	--[[ Highlight bad whitespace
	vim.api.nvim_create_autocmd({"BufRead","BufNewFile"},{
		pattern = {"*.py","*.pyw","*.c","*.h","*.js","*.ts","*.html","*.htm",".vimrc","*.vim"},
		-- TODO convert this
		command = "match BadWhitespace /\s\+$/"
	})]]
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

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require('packer').sync()
	end
end, config = packer_config }
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
