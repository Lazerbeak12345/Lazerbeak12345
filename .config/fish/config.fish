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
set -x GOPATH $HOME/.config/go
fish_add_path -a $HOME/.cargo/bin
fish_add_path -a $HOME/.radicle/bin
fish_add_path -a $HOME/.luarocks/bin
fish_add_path -a $HOME/.bin
fish_add_path -a $GOPATH/bin
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
	abbr -ag ewl eww logs abbr -ag ewld eww logs --debug abbr -ag ewk eww kill
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
	alias ls lsd
	alias tree 'lsd --tree'
	alias cls clear
	abbr --add nivm nvim
	abbr --add vnim nvim
	abbr --add wo workon
	abbr --add woc workonc
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

set -gx WASMTIME_HOME "$HOME/.wasmtime"

string match -r ".wasmtime" "$PATH" > /dev/null; or set -gx PATH "$WASMTIME_HOME/bin" $PATH
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
if type -q pnpm
	set -gx PNPM_HOME "$HOME/.local/share/pnpm"
	set -gx PATH "$PNPM_HOME" $PATH
end
if type -q poetry
	poetry completions fish > ~/.config/fish/completions/poetry.fish
end
