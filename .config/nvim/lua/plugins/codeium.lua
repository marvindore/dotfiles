local utils = require("utils")
return {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
  	enabled = utils.enableCodeium,
    config = function()
        require("codeium").setup({
        })
    end
}
