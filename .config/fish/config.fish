if [ $TERM = linux ] && type -q yaft
	exec yaft
end
if status is-login
	if functions -q bass
		bass source /etc/profile
	else
		echo "Bass isn't installed - you might have a hard time with the /etc/profile"
	end
end

function _migrate_old_path
	set from $argv[1]
	set to $argv[2]
	if not test -d "$from"
		#echo "$from did not exist! migration done!"
		return 0
	end
	if not command -q rsync
		echo "install rsync to auto migrate from $from to $to"
		return 1
	end
	echo "Migrating contents from $from to $to"

	rsync \
		--archive \
		--verbose \
		--remove-source-files \
		--mkpath \
		--human-readable \
		--progress \
		"$from" "$to"

	if test $status -ne 0
		return $status
	end

	# Remove the empty directory structure that remains
	find "$from" -depth -type d -empty -delete

	return $status
end

set -q XDG_DATA_HOME; or set -x XDG_DATA_HOME "$HOME/.local/share"
set -q XDG_CONFIG_HOME; or set -x XDG_CONFIG_HOME "$HOME/.config"
set -q XDG_CACHE_HOME; or set -x XDG_CACHE_HOME "$HOME/.cache"
set -q XDG_BIN_HOME; or set -x XDG_BIN_HOME "$HOME/.local/bin"
# TODO: projects -> Projects

# Below, we force things to use XDG locations, if possible.

set -x GOPATH "$XDG_DATA_HOME/go"
_migrate_old_path "$HOME/go/" "$GOPATH"
set -x GOBIN "$XDG_BIN_HOME"
_migrate_old_path "$GOPATH/bin/" "$GOBIN"

set -x CARGO_HOME "$XDG_DATA_HOME/cargo"
_migrate_old_path "$HOME/.cargo/" "$CARGO_HOME"
if command -q cargo
	fish_add_path "$CARGO_HOME/bin"
end

set -x RUSTUP_HOME "$XDG_DATA_HOME/rustup"
_migrate_old_path "$HOME/.rustup/" "$RUSTUP_HOME"

# Luarocks stupidly doesn't support XDG and isn't ENV-configurable.
if command -q luarocks
	fish_add_path "$HOME/.luarocks/bin"
end

if command -q pnpm
	fish_add_path "$XDG_DATA_HOME/pnpm/bin"
end

set -x WASMTIME_HOME "$XDG_DATA_HOME/wasmtime"
_migrate_old_path "$HOME/.wasmtime/" "$WASMTIME_HOME"
if command -q wasmtime
	fish_add_path "$WASMTIME_HOME/bin"
end

set -x GEM_HOME "$XDG_DATA_HOME/gem"
_migrate_old_path "$HOME/.gem/" "$GEM_HOME"
if command -q gem
	fish_add_path "$GEM_HOME/bin"
end

_migrate_old_path "$HOME/.bin/" "$XDG_BIN_HOME"
_migrate_old_path "$HOME/bin/" "$XDG_BIN_HOME"
fish_add_path "$XDG_BIN_HOME"

function update_nvim -d "Update all nvim packages"
	# https://github.com/RubixDev/mason-update-all#updating-from-cli
	echo Update lazy.nvim plugins
	nvim --headless "+Lazy! sync" +qa
	echo
	echo Update Mason packages
	nvim --headless -c 'autocmd User MasonUpdateAllComplete quitall' -c 'MasonUpdateAll'
end
function make_eww_abbrs
	abbr -ag ewd eww daemon
	abbr -ag ewdd eww daemon --debug
	abbr -ag ewl eww logs
	abbr -ag ewld eww logs --debug
	abbr -ag ewk eww kill
	abbr -ag ewkd eww kill --debug
	abbr -ag ewot eww open taskbar
	abbr -ag ewotd eww open taskbar --debug
	abbr -ag ewr eww reload
	abbr -ag ewrd eww reload --debug
end
# Array indices in fish and lua start at one
function workon -d "Open up an editor on the given project"
	nvim ~/projects/$argv[1]
end
function workonc -d "Open up an editor on the given configuration dir"
	nvim ~/.config/$argv[1]
end
function workons -d "Open up an editor on the given class"
	nvim ~/Documents/school/Fall 2025/$argv[1]
end
alias ip "ip -color=auto"
alias dotfiles "/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
if status is-interactive
	if type -q nvimpager
		alias less nvimpager
		if set -q NVIM || set -q VIM
			# TODO: request a -R flag
			set -x PAGER nvimpager -c
			# set -x PAGER nvimpager -p -- -c '"syn off"'
		else
			set -x PAGER nvimpager
		end
	end
	alias more less
	alias vim nvim
	alias pnpx 'pnpm dlx'
	if type -q lsd
		alias ls lsd
		alias tree 'lsd --tree'
	end
	alias cls clear
	abbr --add nivm nvim
	abbr --add vnim nvim
	abbr --add wo workon
	abbr --add woc workonc
	abbr --add wos workons
	abbr --add dotf dotfiles
	abbr --add dof dotfiles
end
function fish_greeting
	if type -q fastfetch
		fastfetch
	end
	set --local todofile ~/.todo
	set --local lines (wc -l < $todofile)
	set --local items (grep "^[^[:blank:]]" -c $todofile)
	echo TODO: "($lines lines, $items items)"
	head $todofile
	echo -e \n$fish_greeting
end

if type -q nvim
	set -x VISUAL nvim # Full screen editor
	#set -x EDITOR "nvim -e" # Non-visual editor
	set -x EDITOR $VISUAL # nvim will behave properly if it must be non-visual, afaik. lots of apps just use this variable to find the editor.
	set -x GIT_EDITOR $VISUAL # Git uses vim otherwise.
	if type -q git
		git config --global merge.tool nvimdiff3
		git config --global merge.conflictstyle diff3
		git config --global mergetool.prompt false
	end
end
# Rustup seems to keep disapearing for months at a time....
if type -q rustup
	rustup completions fish > ~/.config/fish/completions/rustup.fish
end
if type -q starship
	starship completions fish > ~/.config/fish/completions/starship.fish
	starship init fish | source
end
if type -q poetry
	poetry completions fish > ~/.config/fish/completions/poetry.fish
end
