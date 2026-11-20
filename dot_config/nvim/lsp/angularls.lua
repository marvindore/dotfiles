-- Angular LS. Attaches only in Angular projects, next to vtsls (see lua/utils/ts_server.lua).
local ts = require("utils.ts_server")
local uv = vim.uv

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local warned_roots = {}

local function get_angularls_cmd(root)
  local nm = root .. "/node_modules"

  -- 1) USE PROJECT-LOCAL SERVER IF AVAILABLE, 2) FALLBACK TO MASON INSTALL
  for _, server in ipairs({ nm .. "/.bin/ngserver", vim.fn.stdpath("data") .. "/mason/bin/ngserver" }) do
    if path_exists(server) then
      return {
        server,
        "--stdio",
        "--tsProbeLocations", nm,
        "--ngProbeLocations", nm,
      }
    end
  end

  if not warned_roots[root] then
    warned_roots[root] = true
    vim.notify(
      "Angular LS not found. Run: npm install --save-dev @angular/language-service",
      vim.log.levels.ERROR,
      { title = "Angular Language Server" }
    )
  end
  return nil
end

return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start(get_angularls_cmd(config.root_dir), dispatchers)
  end,
  filetypes = { "typescript", "html", "typescriptreact", "htmlangular" },
  -- Attach only in Angular projects that have ngserver; root_dir runs before cmd.
  root_dir = function(bufnr, on_dir)
    local root = ts.root(bufnr)
    if ts.is_angular(root) and get_angularls_cmd(root) then
      on_dir(root)
    end
  end,
}
