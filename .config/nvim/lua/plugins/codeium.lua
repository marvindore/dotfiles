return {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
  	enabled = vim.g.enableCodeium,
    config = function()
        require("codeium").setup({
        })
    end
}
