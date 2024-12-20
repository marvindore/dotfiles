return {
  "nvim-neotest/neotest",
  keys = {
    { "<leader>tt", "<cmd>lua require('neotest').summary.toggle()<CR>", desc = "Toggle Neotest" }
  },
  dependencies = {
    "nvim-neotest/nvim-nio",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
    "nvim-neotest/neotest-go",
    "haydenmeade/neotest-jest",
    "Issafalcon/neotest-dotnet",
    -- "Decodetalkers/csharpls-extended-lsp.nvim",
    "stevanmilic/neotest-scala",
    "rouge8/neotest-rust",
    -- "mrcjkb/neotest-haskell",
    "nvim-neotest/neotest-vim-test",
    'vim-test/vim-test',
  },

  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
        }),
        require "neotest-rust",
        require("neotest-dotnet")({
          dap = { 
            args = {justMyCode = false },
            adapter_name = "netcoredbg"
          }
        }),
        require "neotest-scala",
        -- require "neotest-haskell",
        require "neotest-jest",
        require "neotest-go",
        require "neotest-plenary",
        require("neotest-vim-test")({
          ignore_file_types = { "python", "vim", "lua", "cs", "rust", "scala" }, --, "haskell"
        }),
      },
    })
  end
}
