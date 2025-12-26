local project_modules = vim.fn.getcwd() .. '/node_modules'
local cmd = {
  'ngserver', '--stdio',
  '--tsProbeLocations', project_modules,
  '--ngProbeLocations', project_modules,
  '--angularCoreVersion", "15.2.10'
}

return {
  cmd = cmd,
  filetypes = { "angular", "typescript", "html", "typescriptreact", "typescript.tsx", "htmlangular" },
  root_markers = { "angular.json", "nx.json" }
}
