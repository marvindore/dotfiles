-- ty language server configuration (Astral's Python LSP). Primary Python LSP.
local root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" }

-- Prefer the project venv ty over the global (Mason / uv tool) one.
local function ty_bin(root)
  local venv_ty = root and vim.fs.joinpath(root, ".venv", "bin", "ty")
  if venv_ty and vim.fn.executable(venv_ty) == 1 then
    return venv_ty
  end
  return "ty"
end

return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ ty_bin((config or {}).root_dir), "server" }, dispatchers)
  end,
  filetypes = { "python" },
  root_markers = root_markers,
  settings = {
    ty = {
      diagnosticMode = "openFilesOnly",
      inlayHints = {
        variableTypes = true,
        callArgumentNames = true,
      },
    },
  },
}
