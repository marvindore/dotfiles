return {
  {
    "igorlfs/nvim-dap-view",
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {
      winbar = {
        show = true,
        sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
        default_section = "watches",
        base_sections = {
          breakpoints = { keymap = "B", label = "Breakpoints [B]" },
          scopes      = { keymap = "S", label = "Scopes [S]" },
          exceptions  = { keymap = "E", label = "Exceptions [E]" },
          watches     = { keymap = "W", label = "Watches [W]" },
          threads     = { keymap = "T", label = "Threads [T]" },
          repl        = { keymap = "R", label = "REPL [R]" },
          sessions    = { keymap = "K", label = "Sessions [K]" },
          console     = { keymap = "C", label = "Console [C]" },
        },
        custom_sections = {},
        controls = {
          enabled = false,
          position = "right",
          buttons = {
            "play",
            "step_into",
            "step_over",
            "step_out",
            "step_back",
            "run_last",
            "terminate",
            "disconnect",
          },
        },
      },
      windows = {
        size = 0.25,
        position = "below",
        terminal = {
          size = 0.5,
          position = "left",
          hide = {},
        },
      },
      icons = {
        disabled = "",
        disconnect = "",
        enabled = "",
        filter = "󰈲",
        negate = " ",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = "",
      },
      help = { border = nil },
      switchbuf = "usetab",
      auto_toggle = false,
      follow_tab = false,
    },
    config = function(_, opts)
      require("dap-view").setup(opts)

      local dap = require("dap")
      local dapview = require("dap-view")
      local icons = require("config.icons")

      dap.listeners.before.attach.dapui_config = function()
        dapview.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapview.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapview.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapview.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = icons.emoji.Anger,         texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = icons.emoji.Poop,  texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",    { text = icons.emoji.OrangeDiamond, texthl = "", linehl = "", numhl = "" })
    end,
  },
}
