if test -z $NATE_PATH_MODDED
	set -xp PATH $HOME/.cargo/bin
	set -xa PATH $HOME/.radicle/bin
	set -xa PATH $HOME/.luarocks/bin
	set -xa PATH $HOME/.bin
	set -x NATE_PATH_MODDED
end
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
alias dotfiles "/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
if status is-interactive
	alias more less
	alias vim nvim
	alias ls exa
	alias tree 'exa -T'
	alias cls clear
	abbr --add nivm nvim
	abbr --add vnim nvim
	abbr --add wo workon
	abbr --add woc workonc
	abbr --add dotf dotfiles
	abbr --add dof dotfiles
end
function fish_greeting
	echo TODO:
	cat ~/.todo
	echo -e \n$fish_greeting
end

set -gx WASMTIME_HOME "$HOME/.wasmtime"

string match -r ".wasmtime" "$PATH" > /dev/null; or set -gx PATH "$WASMTIME_HOME/bin" $PATH
set -x VISUAL nvim # Full screen editor
set -x EDITOR "nvim -e" # Non-visual editor
set -x GIT_EDITOR $VISUAL # Git uses vim otherwise.
# Rustup seems to keep dissapearing for months at a time....
if type --query rustup
	rustup completions fish > ~/.config/fish/completions/rustup.fish
end
starship completions fish > ~/.config/fish/completions/starship.fish
starship init fish | source

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end
