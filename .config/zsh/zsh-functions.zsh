# ~/.config/zsh/zsh-functions.zsh

# Function to source plugin scripts from a GitHub-style path
zsh_add_plugin() {
  local plugin_path="$HOME/.config/zsh/plugins/${1##*/}"
  local plugin_file="$plugin_path/${1##*/}.plugin.zsh"

  if [[ -f "$plugin_file" ]]; then
    source "$plugin_file"
  elif [[ -f "$plugin_path/${1##*/}.zsh" ]]; then
    source "$plugin_path/${1##*/}.zsh"
  elif [[ -f "$plugin_path/$1.zsh" ]]; then
    source "$plugin_path/$1.zsh"
  elif [[ -f "$plugin_path/$1.plugin.zsh" ]]; then
    source "$plugin_path/$1.plugin.zsh"
  else
    for f in "$plugin_path"/*.zsh; do
      [[ -f "$f" ]] && source "$f"
    done
  fi
}

# Function to source config files from $ZDOTDIR or ~/.zsh
zsh_add_file() {
  local file="$ZDOTDIR/$1.zsh"
  local file_nosuff="$ZDOTDIR/$1"
  if [[ -f "$file" ]]; then
    [[ -f "$file" ]] && source "$file"
  elif [[ -f "$file_nosuff" ]]; then
    [[ -f "$file_nosuff" ]] && source "$file_nosuff"
  fi
}


n() {
  local dir
  dir=$(zoxide query "$@")
  if [ -z "$dir" ]; then
    echo "No match found."
  else
    nvim "$dir"
  fi
}
