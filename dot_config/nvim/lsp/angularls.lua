local uv = vim.loop

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function get_angularls_cmd()
  local root = vim.fs.root(0, { "angular.json", "nx.json", "package.json" }) or vim.fn.getcwd()
  local nm = root .. "/node_modules"
  local local_server = nm .. "/.bin/ngserver"

  -- Check if this is an Angular project
  local is_angular = path_exists(root .. "/angular.json") or path_exists(root .. "/nx.json")

  -- 1) USE PROJECT-LOCAL SERVER IF AVAILABLE
  if path_exists(local_server) then
    return {
      local_server,
      "--stdio",
      "--tsProbeLocations", nm,
      "--ngProbeLocations", nm,
      "--logFile", "/tmp/ngserver.log",
    }
  end

  -- 2) FALLBACK TO MASON INSTALL (probe project node_modules, not mason)
  local global_server = vim.fn.stdpath("data") .. "/mason/bin/ngserver"

  if path_exists(global_server) then
    return {
      global_server, "--stdio",
      "--tsProbeLocations", nm,
      "--ngProbeLocations", nm,
    }
  end

  -- 3) FINAL FALLBACK
  if is_angular then
    vim.notify(
      "Angular LS not found. Run: npm install --save-dev @angular/language-service",
      vim.log.levels.ERROR,
      { title = "Angular Language Server" }
    )
  else
    vim.notify("Angular LS not found (project-local or mason).", vim.log.levels.ERROR)
  end
  return nil
end

  return {
    cmd = get_angularls_cmd(),
    filetypes = { "typescript", "html", "typescriptreact", "typescript.tsx" },
    root_markers = { "angular.json", "nx.json" },
  }
