local project_root = vim.fn.getcwd()
local angular_json = project_root .. '/angular.json'
local nx_json = project_root .. '/nx.json'

-- Only enable Angular LSP if angular.json or nx.json exists
if vim.fn.filereadable(angular_json) == 1 or vim.fn.filereadable(nx_json) == 1 then
  local project_modules = project_root .. '/node_modules'
  local cmd = {
    'ngserver', '--stdio',
    '--tsProbeLocations', project_modules,
    '--ngProbeLocations', project_modules,
    '--angularCoreVersion', '15.2.10'
  }

  return {
    cmd = cmd,
    filetypes = { "typescript", "html", "typescriptreact", "typescript.tsx" },
    root_dir = project_root, -- explicitly set root
  }
else
  -- Return nil so Neovim won't start this LSP
  return nil
end
