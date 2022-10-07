-- This new bootstrapping code was copied from https://github.com/wbthomason/packer.nvim#bootstrapping
local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system{'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path}
		vim.cmd [[packadd packer.nvim]]
		print("had to bootsrap!")
		return true
	end
	return false
end

if vim.env.VIMRUNNING == "1" then
	print("dummy! read before running (override by unsetting $VIMRUNNING)")
	-- Lua never sleeps
	vim.cmd.sleep()
	-- and isn't a quitter
	vim.cmd.qall{ bang = true }
	-- So vim has to take care of it.
else
	vim.env.VIMRUNNING = 1
end

local function configure_lightline()
	-- TODO this is actually slightly broken. look at https://github.com/nvim-lualine/lualine.nvim to fix it
	function _G.lightline_visual_selection()
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
		elseif mode == "<C-v>" then
			return lines_str .. cols_str
		else
			return ''
		end
	end
	function _G.lightline_visual_selection_cond()
		local mode = vim.fn.mode()
		return mode == 'v' or
			mode == 's' or
			mode == 'V' or
			mode == 'S' or
			mode == "<C-v>"
	end
	function _G.custom_fugitive_head()
		local result = vim.api.nvim_eval("FugitiveHead()")
		if result == "" then
			return ""
		end
		return " " ..  result
	end
	function _G.custom_fugitive_head_cond()
		return "" ~= vim.api.nvim_eval("FugitiveHead()")
	end
	-- TODO there's a native way to do this now.
	function _G.LspStatus_getVisible()
		return vim.fn.winwidth(0) > 60 and #vim.lsp.buf_get_clients() > 0
	end
	function _G.LspStatus()
		if LspStatus_getVisible() then
			return require'lsp-status'.status()
		else
			return ''
		end
	end
	--  	"\ 'separator': { 'left': '🙽 ', 'right': '🙼 ' },
	--  	"\ 'separator': { 'left': '🙿 ', 'right': '🙾 ' }
	-- "                                  
	-- "█
	vim.g.lightline = {
		active = {
			left = {
				{ 'mode', 'paste' },
				{ 'fugitive', 'readonly', 'filename', 'modified', 'visual_selection' },
				{ 'lsp_status' }
			}
		},
		component = {
		  readonly= '%{&filetype=="help"?"":&readonly?"":""}',
		  modified= '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
		  lineinfo= " %3l:%-2c",
		  fileformat= "%{winwidth(0) > 70 ? &fileformat : ''}",
		  fileencoding= "%{winwidth(0) > 70 ? &fileencoding : ''}",
		  filetype= "%{winwidth(0) > 70 ? &filetype : ''}",
		  lsp_status= "%{v:lua.LspStatus()}",
		  visual_selection= '%{v:lua.lightline_visual_selection()}',
		  fugitive= '%{v:lua.custom_fugitive_head()}'
		},
		component_visible_condition= {
		  readonly= '(&filetype!="help"&& &readonly)',
		  modified= '(&filetype!="help"&&(&modified||!&modifiable))',
		  fileformat= '(winwidth(0) > 70)',
		  fileencoding= '(winwidth(0) > 70 && &fileencoding !=# "")',
		  filetype= '(winwidth(0) > 70 && &filetype !=# "")',
		  lsp_status= 'v:lua.LspStatus_getVisible()',
		  visual_selection= 'v:lua.lightline_visual_selection_cond()',
		  fugitive= 'v:lua.custom_fugitive_head_cond()'
		},
		component_function = vim.empty_dict(),
		separator= { left= '', right= '' },
		subseparator= { left= '', right= '' }
	}
end

local packer_bootstrap = ensure_packer()

return require'packer'.startup(function(use)
	use 'wbthomason/packer.nvim'
	-- My plugins here
	-- use 'foo1/bar1.nvim'
	-- use 'foo2/bar2.nvim'

	-- Commenting
	--Plug 'tpope/vim-commentary'
	-- The looks of Powerline, but faster
	use{
		'itchyny/lightline.vim',
		config = configure_lightline,
		after = {
			'vim-fugitive',
			'lsp-status.nvim'
		}
	}
	---- Indent lines
	--Plug 'thaerkh/vim-indentguides'
	
	-- Git integration
	--  Genral use
	use 'tpope/vim-fugitive'
	----  Line-per-line indicators and chunk selection
	--Plug 'airblade/vim-gitgutter'
	---- Nicer file management
	--Plug 'preservim/nerdtree'
	--Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
	----Plug 'jistr/vim-nerdtree-tabs'
	--Plug 'Xuyuanp/nerdtree-git-plugin'
	---- Icons
	--Plug 'ryanoasis/vim-devicons'
--
----  This should work on all files (it's python support ain't great)
----Plug 'khzaw/vim-conceal'
----Plug 'jamestomasino-forks/vim-conceal' " This one has better javascript support
----Plug 'Lazerbeak12345/vim-conceal' " This is my blend of a bunch of stuff (my
----    fork of above)
---- Ease of use
--Plug 'vimlab/split-term.vim'
--Plug 'airblade/vim-rooter'
----  Start Screen
--Plug 'mhinz/vim-startify'
---- common dependancies of many nvim plugins
--Plug 'nvim-lua/plenary.nvim'
--Plug 'jose-elias-alvarez/null-ls.nvim'
---- Interactive eval
--Plug 'Olical/conjure'
--
---- Specific file type compat
---- CSV
--Plug 'chrisbra/csv.vim'
---- Racket
--Plug 'wlangstroth/vim-racket'
---- Eww's configuration language, yuck
--Plug 'elkowar/yuck.vim'
---- Anything with parens as well as html
--Plug 'luochen1990/rainbow'
--
---- Language-server protocol
---- Must be after language specific things
	use 'neovim/nvim-lspconfig'
	use{
		'nvim-lua/lsp-status.nvim',
		after = 'nvim-lspconfig' 
	}
----Automate installing some language-servers
--Plug 'williamboman/nvim-lsp-installer'
---- LSP breakdown icons and stuff
--Plug 'onsails/lspkind-nvim'
---- Better folding
--Plug 'pierreglaser/folding-nvim'
--
---- Completion details (uses LSP)
--Plug 'hrsh7th/cmp-nvim-lsp'
--Plug 'hrsh7th/cmp-buffer'
--Plug 'hrsh7th/cmp-path'
--Plug 'hrsh7th/nvim-cmp'
---- Lower the text sorting of completions starting with _
--Plug 'lukas-reineke/cmp-under-comparator'
---- cmdline source
--Plug 'hrsh7th/cmp-cmdline'
---- Snippet source
----  For vsnip users.
--Plug 'hrsh7th/cmp-vsnip'
--Plug 'hrsh7th/vim-vsnip'
----  For luasnip users.
----Plug 'L3MON4D3/LuaSnip'
----Plug 'saadparwaiz1/cmp_luasnip'
----  For ultisnips users.
----Plug 'SirVer/ultisnips'
----Plug 'quangnguyen30192/cmp-nvim-ultisnips'
----  For snippy users.
----Plug 'dcampos/nvim-snippy'
----Plug 'dcampos/cmp-snippy'
---- Git completion source
--Plug 'petertriho/cmp-git'
---- crates.io completion source
--Plug 'saecki/crates.nvim'
---- package.json completion source
--Plug 'David-Kunz/cmp-npm'
---- latex symbol completion support (allows for inserting unicode)
--Plug 'kdheepak/cmp-latex-symbols'
---- Emoji completion support
--Plug 'hrsh7th/cmp-emoji'
---- Pandoc completion
--Plug 'jc-doyle/cmp-pandoc-references'
---- cmdline history completion
----Plug 'dmitmel/cmp-cmdline-history'
---- Fish completion
--Plug 'mtoohey31/cmp-fish'
---- conjure intractive eval completion
--Plug 'PaterJason/cmp-conjure'
---- Use LSP symbols for buffer-style search
--Plug 'hrsh7th/cmp-nvim-lsp-document-symbol'
---- Completion on the vim.lsp apis
--Plug 'hrsh7th/cmp-nvim-lua'
---- Use /usr/share/dict/words for completion
--Plug 'uga-rosa/cmp-dictionary'


-- TODO where'd my config go eh?

----TODO once this whole file is in the lua block, look into https://github.com/wbthomason/packer.nvim
----nvim-cmp setup
---- In the meantime refer to https://github.com/nanotee/nvim-lua-guide
--local cmp = require'cmp'
--local lspkind = require"lspkind"
--require'cmp-npm'.setup{}
--cmp.setup{
--	--Defaults:https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
--	snippet = {
--		-- REQUIRED - you must specify a snippet engine
--		expand = function(args)
--			vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
--			-- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
--			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
--			-- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
--		end,
--	},
--	mapping = {
--		['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
--		['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
--		['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
--		['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
--		['<C-e>'] = cmp.mapping{
--			i = cmp.mapping.abort(),
--			c = cmp.mapping.close(),
--		},
--		['<Tab>'] = cmp.mapping.confirm{ select = true },
--		--[[ TODO this is what some of it was before:
--		--  Use keyboard shortcuts to change to the next or previous sources
--		vim.keymap.set('i', '<c-j>', '<Plug>(completion_next_source)')
--		vim.keymap.set('i', '<c-k>', '<Plug>(completion_prev_source)')
--		]]
--	},
--	sources = cmp.config.sources({
--		{ name = 'nvim_lsp' },
--		{ name = 'vsnip' }, -- For vsnip users.
--		-- { name = 'luasnip' }, -- For luasnip users.
--		-- { name = 'ultisnips' }, -- For ultisnips users.
--		-- { name = 'snippy' }, -- For snippy users.
--		{ name = 'latex_symbols' },
--		{ name = 'emoji', insert = true },
--	--}, {
--		{ name = "git" },
--		{ name = "crates" },
--		{ name = 'npm', keyword_length = 4 },
--		{ name = 'pandoc_references' },
--		{ name = 'nvim_lsp_document_symbol' },
--		{ name = "fish" },
--		{ name = "path" },
--	}, {
--		{
--			name = "dictionary",
--			keyword_length = 2,
--		},
--		{ name = 'nvim_lua' },
--		{ name = 'buffer' },
--		{ name = 'cmdline' },
--	}--[[, {
--		{ name = 'cmdline_history', options = { history_type = ':' } },
--	}]]),
--	sorting = {
--        comparators = {
--            cmp.config.compare.offset,
--            cmp.config.compare.exact,
--            cmp.config.compare.score,
--            cmp.config.compare.recently_used,
--            require"cmp-under-comparator".under,
--            cmp.config.compare.kind,
--            cmp.config.compare.sort_text,
--            cmp.config.compare.length,
--            cmp.config.compare.order,
--        },
--    },
--	formatting = {
--		format = lspkind.cmp_format{
--			with_text = true,
--			--[[
--			symbol_map = {
--				-- Also effects anything else using lspkind
--				Constructor = '🏗 ',
--				Variable = lspkind.presets.default.Field,
--				File = '🗎',
--				Unit = '🞕',
--				Reference = '►',
--				Constant = 'π',
--				Struct = 'ﱖ',
--			},]]
--			menu = {
--				buffer                   = "[Buffer]",
--				nvim_lsp                 = "[LSP]",
--				nvim_lua                 = "[Lua]",
--				latex_symbols            = "[Latex]",
--				vsnip                    = "[VSnip]",
--				--luasnip                  = "[LuaSnip]",
--				--ultisnips                = "[UltiSnips]",
--				--snippy                   = "[Snippy]",
--				emoji                    = "[Emoji]",
--				git                      = "[Git]",
--				crates                   = "[Crates]",
--				npm                      = "[NPM]",
--				pandoc_references        = "[Pandoc]",
--				fish                     = "[Fish]",
--				path                     = "[Path]",
--				cmdline_history          = "[CmdHistory]",
--				cmdline                  = "[Cmd]",
--				nvim_lsp_document_symbol = "[LSPSymbol]",
--				dictionary               = "[Dict]",
--			}
--		},
--	},
--}
---- Use buffer source (then history) for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
--for _, cmd_type in ipairs{'/', '?'} do
--	cmp.setup.cmdline(cmd_type, {
--	  sources = {
--		{ name = 'buffer' },
--	  }, {
--		{ name = 'cmdline_history' },
--	  }
--	})
--end
---- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
--cmp.setup.cmdline(':', {
--  sources = cmp.config.sources({
--    { name = 'path' },
--  }, {
--    { name = 'cmdline' },
--	{ name = 'cmdline_history' },
--  })
--})
--for _, cmd_type in ipairs{'@', '='} do
--  cmp.setup.cmdline(cmd_type, {
--    sources = {
--      { name = 'cmdline_history' },
--    },
--  })
--end
--require"cmp_git".setup()
--require'crates'.setup()
--require"cmp_dictionary".setup{
--    dic = {
--        ["*"] = "/usr/share/dict/words",
--        --["markdown"] = { "path/to/mddict", "path/to/mddict2" },
--        --["javascript,typescript"] = { "path/to/jsdict" },
--    },
--    -- The following are default values, so you don't need to write them if you don't want to change them
--    --exact = 2,
--    --async = true,
--    --capacity = 5,
--    --debug = false, 
--}
----lsp setup
--local lsp_status = require'lsp-status'
--lsp_status.config{
--	status_symbol = '', -- The default V breaks some layout stuff
--	show_filename = false, -- Takes up too much space
--	kind_labels = lspkind.symbol_map
--}
--lsp_status.register_progress()
--local function my_on_attach(...)
--	--[[
--	TODO
--	[LSP] Accessing client.resolved_capabilities is deprecated, update your plugins
--	or configuration to access client.server_capabilities instead.The new key/value
--	pairs in server_capabilities directly match those defined in the language server
--	protocol
--	]]
--	lsp_status.on_attach(...)
--	require'folding'.on_attach(...)
--end
--local default_args={
--	on_attach=my_on_attach,
--	capabilities=require'cmp_nvim_lsp'.update_capabilities(lsp_status.capabilities)
--}
--require"nvim-lsp-installer".on_server_ready(function(server)
--    -- (optional) Customize the options passed to the server
--    -- if server.name == "tsserver" then
--    --     options.root_dir = function() ... end
--    -- end
--
--    -- This setup() function is exactly the same as lspconfig's setup function.
--    -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--    server:setup(default_args)
--end)
--local lspconfig=require'lspconfig'
---- Confirmed to have been used
--lspconfig.racket_langserver.setup(default_args)
--lspconfig.clangd.setup(default_args)
----vim.lsp.set_log_level("debug")
--local null_ls = require"null-ls"
--null_ls.setup{
--    sources = {
--		--[[ TODO was super laggy, and duplicative in nature
--		null_ls.builtins.code_actions.eslint,
--		null_ls.builtins.diagnostics.eslint,
--		null_ls.builtins.formatting.eslint,
--		null_ls.builtins.completion.vsnip,
--		null_ls.builtins.diagnostics.fish,
--		null_ls.builtins.formatting.fish_indent,
--		null_ls.builtins.diagnostics.standardjs,
--		null_ls.builtins.formatting.standardjs,
--		null_ls.builtins.diagnostics.tsc,
--		null_ls.builtins.hover.dictionary
--		]]
--    }
--}
--
--vim.g.indentguides_spacechar = '⍿'
--vim.g.indentguides_tabchar = '⟼'
--vim.g.indentguides_concealcursor_unaltered = 'nonempty value'
----|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
----|‖⃒⃓⍿⎸⎹⁞⸾⼁︳︴｜¦❘❙❚⟊⟾⤠⟼
--vim.g.vimsyn_embed = 'l'
--
---- Inline diagnostic alerts
--vim.diagnostic.config{
--	severity_sort = true,
--	virtual_text = {
--		prefix = '🛈'
--	}
--}
--
---- vim.g.rainbow_active = 1 -- set to 0 if you want to enable it later via :RainbowToggle
--vim.g.rainbow_active = 0
--
---- see the docstrings for folded code
--vim.g.SimpylFold_docstring_preview = 1
--
--vim.g.rooter_change_directory_for_non_project_files = 'current'
---- vim.g.rooter_patterns = ['.git', 'mod.conf', 'modpack.conf','game.conf','texture_pack.conf']
--
--local function t(str)
--	return vim.api.nvim_replace_termcodes(str, true, true, true)
--end
--
---- TODO fix
---- nvim_lsp completeion settings
----  Use <Tab> and <S-Tab> to navigate through popup menu
--vim.keymap.set('i', '<Tab>', function()
--	return vim.fn.pumvisible() == 1 and t'<C-n>' or t'<Tab>'
--end, {expr = true})
--vim.keymap.set('i', '<S-Tab>', function()
--	return vim.fn.pumvisible() == 1 and t'<C-p>' or t'<S-Tab>'
--end, {expr = true})
--
--vim.keymap.set('n', '<Leader>d', vim.diagnostic.goto_next)
--
---- Enable folding with the spacebar
--vim.keymap.set('n', '<space>', 'za')
--
---- Go back one file in current buffer
--vim.keymap.set('n', '<Leader><Leader>', '<c-^>')
--
---- Map <Esc> to exit terminal-mode (stolen from nvim's :help terminal-input then modified for lua)
--vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
--
---- Keyboard shortcut to open nerd tree
--vim.keymap.set('', '<Leader>n', '<Plug>NERDTreeTabsToggle<CR>')
--
---- Make it a tad easier to change the terminal back to a buffer
--vim.keymap.set('', '<Leader>]', '<C-\\><C-n>')
--
---- Reccomended settings for nvim-cmp
--vim.o.completeopt = 'menu,menuone,noselect'
--
--vim.o.showmode = false -- Hide the default mode text (e.g. -- INSERT -- below the statusline)
---- print options
---- set printoptions=paper:letter
--
---- display line numbers
--vim.o.number = true --  If this is used with [[relativenumber]], then it shows the current lineno on the current line (as opposed to `0`)
--vim.o.relativenumber = true
--
--vim.o.tabstop = 4
--vim.o.shiftwidth = 4
--vim.o.backspace = 'indent,eol,start'
--
---- Use sys clipboard
--vim.o.clipboard = 'unnamedplus'
--
---- Title magic.
--vim.o.title = true
--
---- I don't like presssing more most of the time
--vim.o.more = false
--
---- This is the global vim refresh interval. Multiple tools, such as
---- gitgutter and coc reccomend turning this number down. It's measured in
---- milliseconds, and defaults to 4000
--vim.o.updatetime = 1000
--
---- Enable folding
--vim.o.foldmethod = 'syntax'
----vim.o.foldmethod = 'indent'
--vim.o.foldlevel=99
--vim.o.foldminlines = 3
--
---- Load file automatically when changes happen
--vim.o.autoread = true
--
----enable syntax highlighting (optimised for dark backgrounds)
----vim.o.background='dark'
--
---- TODO broken
---- Always underline the current line
---- change cursor on insert mode. doesn't always work
---- below two lines work in konsole
----vim.o.t_SI = "\\e[3 q" -- insert
----vim.o.t_EI = "\\e[1 q" -- command
--
---- Allow for syntax checking in racket. The catches: Security(?) and lag.
---- NOTE: LSP is better
----vim.g.syntastic_enable_racket_racket_checker = 1 -- I want it to check racket file syntax
--vim.api.nvim_create_autocmd("TextYankPost", {
--	pattern = "*",
--	callback = function()
--		vim.highlight.on_yank()
--	end
--})
--vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
--	pattern = "*.rkt",
--	callback = function()
--		vim.o.tabstop = 2
--		vim.o.softtabstop = 2
--		vim.o.shiftwidth = 2
--		vim.o.textwidth = 79
--		vim.o.expandtab = true
--		vim.o.autoindent = true
--		vim.o.fileformat = "unix"
--		vim.o.lisp = true
--	end
--})
----[[ Highlight bad whitespace
--vim.api.nvim_create_autocmd({"BufRead","BufNewFile"},{
--	pattern = {"*.py","*.pyw","*.c","*.h","*.js","*.ts","*.html","*.htm",".vimrc","*.vim"},
--	-- TODO convert this
--	command = "match BadWhitespace /\s\+$/"
--})]]
----[[ (failed) Attempt to disable numbers on terminal only.
--vim.api.nvim_create_autocmd({ "TermOpen " }, {
--	pattern = "*",
--	callback = function()
--		vim.o.number = false
--		vim.o.relativenumber = false
--	end
--})]]
---- Popup windows tend to be unreadable with a pink background
--vim.api.nvim_set_hl(0, "Pmenu", {})

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
-- vim.o.ambiwidth="double" -- use this if the arrows are cut off
