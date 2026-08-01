vim.pack.add({
  {
    src = "https://github.com/stevearc/overseer.nvim",
    data = {
      cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerClose", "OverseerTaskAction", "OverseerRestartLast" },
      keys = {
        { lhs = "<leader>or", rhs = "<cmd>OverseerRun<cr>", mode = "n", desc = "Run project task" },
        { lhs = "<leader>ot", rhs = "<cmd>OverseerToggle<cr>", mode = "n", desc = "Toggle task list" },
        { lhs = "<leader>oa", rhs = "<cmd>OverseerTaskAction<cr>", mode = "n", desc = "Task action" },
        { lhs = "<leader>ol", rhs = "<cmd>OverseerRestartLast<cr>", mode = "n", desc = "Restart last task" },
      },
      after = function(_)
        require("overseer").setup({
          templates = { "builtin" },
          task_list = {
            direction = "bottom",
            min_height = 25,
            max_height = 40,
            default_detail = 1,
          },
          task_runner = {
            autostart_on_load = "all",
            keep_finished = true,
          },
          actions = {
            ["dispose"] = {
              hidden = false,
            },
          },
          priorities = {
            "user",
            "cmake",
            "dotnet",
            "gulpfile",
            "just",
            "justfile",
            "make",
            "mise",
            "npm",
            "package.json",
            "mason.nvim",
            "compiler",
            "buildins",
          },
        })
      end,
    },
  },
}, {
  load = function(p)
    local spec = p.spec.data or {}
    spec.name = p.spec.name
    require("lze").load(spec)
  end,
})
