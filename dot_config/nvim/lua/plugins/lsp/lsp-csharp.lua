return {
  "seblj/roslyn.nvim",
  enabled = vim.g.enableCsharp,
  dependencies = {
    "williamboman/mason.nvim",
  },
  config = function()
    require("roslyn").setup()

    -- Install roslyn after plugin loads
    local registry = require("mason-registry")
    if not registry.is_installed("roslyn") then
      vim.cmd("MasonInstall roslyn")
    end
  end,
}
