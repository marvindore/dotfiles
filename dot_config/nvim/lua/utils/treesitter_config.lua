local M = {}
function M.setup()
  local ts = require("nvim-treesitter")
  ts.setup({})
  vim.defer_fn(function()
    ts.install({
      "bash","cmake","comment","css","cuda","dockerfile","gitignore","graphql","html","http",
      "javascript","jsdoc","json","json5","latex","lua","make","markdown","markdown_inline",
      "python","query","regex","scss","sql","svelte","todotxt","toml","tsx","typescript",
      "vim","vimdoc","vue","yaml",
    })
  end, 0)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter_core_integration", { clear = true }),
    pattern = "*",
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
      if vim.bo[args.buf].buftype ~= "" then return end
      if vim.bo[args.buf].filetype == "minifiles" then return end
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
    end,
  })
end
return M
