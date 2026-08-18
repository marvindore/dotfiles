#!/bin/bash
# Detect project type and show relevant environment info
# Cached for performance (updates every 5 seconds)

CACHE_DIR="$HOME/.cache/tmux"
CACHE_FILE="$CACHE_DIR/project-info-cache"
CACHE_TTL=5  # seconds

mkdir -p "$CACHE_DIR" 2>/dev/null

# Check if cache is still valid
if [[ -f "$CACHE_FILE" ]]; then
  CACHE_AGE=$(($(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null || stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [[ $CACHE_AGE -lt $CACHE_TTL ]]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Get current working directory from tmux pane
PWD="#{pane_current_path}"

# Detect project type
PROJECT_INFO=""

# Node.js
if [[ -f "$PWD/package.json" ]]; then
  NODE_VER=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1-2)
  PROJECT_INFO="🟢 node:$NODE_VER"
fi

# Python
if [[ -f "$PWD/pyproject.toml" || -f "$PWD/setup.py" || -f "$PWD/requirements.txt" ]]; then
  PY_VER=$(python3 --version 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)
  if [[ -n "$VIRTUAL_ENV" ]]; then
    PROJECT_INFO="🐍 python:$PY_VER ✓"
  else
    PROJECT_INFO="🐍 python:$PY_VER"
  fi
fi

# Rust
if [[ -f "$PWD/Cargo.toml" ]]; then
  RUSTC_VER=$(rustc --version 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)
  PROJECT_INFO="🦀 rust:$RUSTC_VER"
fi

# Go
if [[ -f "$PWD/go.mod" ]]; then
  GO_VER=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
  PROJECT_INFO="🐹 go:$GO_VER"
fi

# C# / .NET
if [[ -f "$PWD/global.json" || -n $(find "$PWD" -maxdepth 1 -name '*.csproj' -o -name '*.fsproj' 2>/dev/null) ]]; then
  DOTNET_VER=$(dotnet --version 2>/dev/null)
  PROJECT_INFO="🧬 dotnet:$DOTNET_VER"
fi

# Java
if [[ -f "$PWD/pom.xml" || -f "$PWD/build.gradle" ]]; then
  JAVA_VER=$(java -version 2>&1 | grep version | awk '{print $3}' | sed 's/"//g' | cut -d. -f1-2)
  if [[ -f "$PWD/pom.xml" ]]; then
    PROJECT_INFO="☕ maven:$JAVA_VER"
  else
    PROJECT_INFO="☕ gradle:$JAVA_VER"
  fi
fi

# Ruby
if [[ -f "$PWD/Gemfile" || -f "$PWD/.ruby-version" ]]; then
  RUBY_VER=$(ruby --version 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)
  PROJECT_INFO="💎 ruby:$RUBY_VER"
fi

# Cache the result
echo -n "$PROJECT_INFO" > "$CACHE_FILE"
echo "$PROJECT_INFO"
