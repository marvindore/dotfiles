return {
  "Vigemus/iron.nvim",
  cmd = "IronRepl",
  config = function()
    local iron = require("iron.core")

    iron.setup({
      config = {
        scratch_repl = true, -- discard repls,
        repl_definition = {
          cs = {
            command = { "csharprepl"}
          },
          java = {
            command = { "jshell" }
          },
          go = {
            command = { "gore" }
          },
          python = {
            command = { "python3" },
            format = require("iron.fts.common").bracketed_paste_python
          },
          javascript = {
            command = { "node" },
          },
          typescript = {
            command = { "tsx" },
          },
          typescriptreact = {
            command = { "tsx" }
          },
          javascriptreact = {
            command = { "tsx" }
          }
        },
        repl_open_cmd = require("iron.view").split.vertical.botright("40%")
      }
    })
  end
}
