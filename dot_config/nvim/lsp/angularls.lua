local uv = vim.loop

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function get_angularls_cmd()
  local root = vim.fn.getcwd()
  local nm = root .. "/node_modules"
  local local_server = nm .. "/.bin/ngserver"

  -- 1) USE PROJECT-LOCAL SERVER IF AVAILABLE
  if path_exists(local_server) then
    return {
      local_server,
      "--stdio",
      "--tsProbeLocations", nm,
      "--ngProbeLocations", nm,
      '--angularCoreVersion', '15.2.10'
    }
  end

  -- 2) FALLBACK TO MASON INSTALL
  local mason_root = vim.fn.stdpath("data") .. "/mason/packages/angular-language-server"
  local global_server = vim.fn.stdpath("data") .. "/mason/bin/ngserver"

  if path_exists(global_server) then
    return {
      global_server, "--stdio",
      "--tsProbeLocations", mason_root,
      "--ngProbeLocations", mason_root,
    }
  end

  -- (Optional) final fallback
  vim.notify("Angular LS not found (project-local or mason).", vim.log.levels.ERROR)
  return nil
end

  return {
    cmd = get_angularls_cmd(),
    filetypes = { "typescript", "html", "typescriptreact", "typescript.tsx" },
    root_markers = { "angular.json", "nx.json" },
  }
