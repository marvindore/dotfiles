#Sublime text symmlink
#ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl

source ~/.alias
source ~/.secrets
source ~/.workrc

# Path
export PATH=/usr/local/sbin:$PATH
export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
export PATH="$HOME/.executables:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# Macos Paths
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Add .NET Core SDK tools
export PATH="$PATH:$HOME/.dotnet/tools"

# Environment variables set everywhere
export EDITOR="nvim"
export VISUAL="$EDITOR"
export BROWSER="chrome"
export flake="nvim $HOME/dotfiles/.config/nix-darwin/flake.nix"

# Enable colors and change prompt:
autoload -U colors && colors
export COLORTERM=truecolor

# History in cache directory:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.cache/zsh/history

# Environment Vars
#export VIRTUAL_ENV="$HOME/neovim/debug/python/debugpy"
export E="/Volumes/Nvme SSD"
export EHOME=$E/$HOME

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select

# Auto complete with case insensitivity
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=*r:|=*''l:|=* r:|=*'

zmodload zsh/complist
compinit
_comp_options+=(globdots) # Include hidden files

# Colors
autoload -Uz colors && colors

# Useful Functions
source "$ZDOTDIR/zsh-functions"

# Normal files to source
zsh_add_file "zsh-exports"
zsh_add_file "zsh-vim-mode"
zsh_add_file "zsh-aliases"
zsh_add_file "zsh-prompt"

# Plugins
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "hlissner/zsh-autopair"
# zsh_add_completion "esc/conda-zsh-completion" false
# For more plugins: https://github.com/unixorn/awesome-zsh-plugins
# More completions https://github.com/zsh-users/zsh-completions

# Key-bindings
bindkey -s '^o' 'ranger^M'
bindkey -s '^f' 'zi^M'
bindkey -s '^s' 'ncdu^M'
# bindkey -s '^n' 'nvim $(fzf)^M'
# bindkey -s '^v' 'nvim\n'
bindkey -s '^z' 'zi^M'
bindkey '^[[P' delete-char
bindkey "^p" up-line-or-beginning-search # Up
bindkey "^n" down-line-or-beginning-search # Down
bindkey "^k" up-line-or-beginning-search # Up
bindkey "^j" down-line-or-beginning-search # Down
bindkey -r "^u"
bindkey -r "^d"

# FZF
# TODO update for mac
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f $ZDOTDIR/completion/_fnm ] && fpath+="$ZDOTDIR/completion/"
# export FZF_DEFAULT_COMMAND='rg --hidden -l ""'
compinit

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line

# For QT Themes
export QT_QPA_PLATFORMTHEME=qt5ct]]

rmd () {
  pandoc $1 | lynx -stdin
}

# Increase file count for "too many files open" error
ulimit -n 10240

# GO
export GOPATH=$HOME/go
#export GOROOT=$HOME/.asdf/shims
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin:${GOPATH}/bin"

export PATH="$PATH:/home/marvin/.local/share/lvim/distant.nvim/bin"

# dotnet
#export DOTNET_ROOT="$HOME/.dotnet"
#export PATH="$PATH:/home/marvin/.dotnet"
. ~/.asdf/plugins/dotnet/set-dotnet-env.zsh

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
