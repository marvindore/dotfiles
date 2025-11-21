return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      markdown = { 'vale', }
    }
vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
  group = vim.api.nvim_create_augroup('lint', { clear = true }),
  callback = function()
    lint.try_lint()
    --local on_demand_linters = {"cspell"}
    local function lint_cspell()
       lint.try_lint({"cspell"})
    end
    vim.keymap.set("n", "<leader>cll", lint_cspell, { desc = "Cspell Lint On"})
    vim.keymap.set("n", "<leader>cln", vim.diagnostic.reset, { desc = "Cspell Lint Off"})
  end
})

  end
}
