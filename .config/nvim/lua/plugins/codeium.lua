return {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
  	enabled = vim.g.enableCodeium,
    config = function()
        require("codeium").setup({
        })
    end
}
