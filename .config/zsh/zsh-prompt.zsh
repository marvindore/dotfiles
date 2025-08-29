# ~/.zshrc - Enhanced Lightweight Prompt Configuration

# Load colors and vcs_info
autoload -Uz vcs_info
autoload -Uz colors && colors

# Enable git support
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%{$fg[blue]%}[%{$fg[red]%}%m%u%c%{$fg[yellow]%}%{$fg[magenta]%} %b%{$fg[blue]%}]'

# Git untracked file hook
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]] && \
     git status --porcelain | grep '??' &>/dev/null ; then
    hook_com[staged]+='!' # signify new files with a bang
  fi
}

# Enable prompt substitution
setopt prompt_subst

show_python_version() {
  [[ -f requirements.txt || -f pyproject.toml ]] && echo "🐍 $(python3 --version 2>/dev/null)"
}

show_python_env() {
  local env=""
  if [[ -n "$VIRTUAL_ENV" ]]; then
    env="🐍 active:$(basename "$VIRTUAL_ENV")"
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    env="🐍 active:$CONDA_DEFAULT_ENV"
  elif command -v poetry &>/dev/null && [[ -f pyproject.toml ]]; then
    env="🐍 active:$(poetry env info --name 2>/dev/null)"
  elif [[ -d .venv ]]; then
    env="(not activated)"
  fi

  [[ -n "$env" ]] && echo -n "$env"
}

show_node_env() {
  if command -v nvm &>/dev/null && [[ -n "$NVM_BIN" ]]; then
    echo "🟢 node:$(node -v)"
  fi
}

show_ruby_env() {
  if command -v rbenv &>/dev/null; then
    echo "💎 ruby:$(rbenv version-name)"
  fi
}


show_rust_env() {
  [[ -f Cargo.toml ]] && echo "🦀 rust:$(rustc --version)"
}


show_go_env() {
  [[ -f go.mod ]] && echo "🐹 go:$(go version)"
}

show_java_env() {
  [[ -f pom.xml || -f build.gradle ]] && echo "☕ java:$(java -version 2>&1 | head -n 1)"
}

show_dotnet_env() {
  if [[ -f global.json || -n $(find . -maxdepth 1 -name '*.csproj' -o -name '*.fsproj') ]]; then
    local sdk_version=$(dotnet --version 2>/dev/null | head -n 1 | awk '{print $1}')
    echo "🧬 dotnet:$sdk_version"
  fi
}

show_env_summary() {
  local parts=()
  local py=$(show_python_env)
  [[ -n "$py" ]] && parts+=("$py")

  local node=$(show_node_env)
  [[ -n "$node" ]] && parts+=("$node")

  local ruby=$(show_ruby_env)
  [[ -n "$ruby" ]] && parts+=("$ruby")

  local rust=$(show_rust_env)
  [[ -n "$rust" ]] && parts+=("$rust")

  local go=$(show_go_env)
  [[ -n "$go" ]] && parts+=("$go")

  local java=$(show_java_env)
  [[ -n "$java" ]] && parts+=("$java")

  local dotnet=$(show_dotnet_env)
  [[ -n "$dotnet" ]] && parts+=("$dotnet")

  echo -n "${(j: :)parts}"
}

# Set prompt
function set_prompt() {
  vcs_info
  local exit_status=$?
  local status_indicator=""
  [[ $exit_status -ne 0 ]] && status_indicator="%{$fg[red]%}❌ "

  if [[ -n "$SSH_CONNECTION" ]]; then
    local host=$(hostname)
    PROMPT="${status_indicator}%{$fg[green]%}[$USER@${host}] %{$fg[cyan]%}%~%{$reset_color%} ${vcs_info_msg_0_}
❯ "
  else
    PROMPT="${status_indicator}%{$fg[blue]%}[$USER] %{$fg[cyan]%}%~%{$reset_color%} ${vcs_info_msg_0_}
❯ "
  fi

    RPROMPT="$(show_env_summary) (%j) $(date +'%H:%M')"
}

# Register prompt function
precmd_functions+=(set_prompt)

# Final newline before each prompt
precmd() { print "" }
