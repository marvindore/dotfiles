-- ruff: lint + format only. ty owns hover.
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
}
