return {
  "yetone/avante.nvim",
  cmd = "AvanteToggle",
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  enabled = vim.g.enableAvante,
  opts = {
    -- add any opts here
       provider = "gemini", -- openai | ollama | copilot
       vendors = {
         ollama = {
           api_key_name = "",
           endpoint = "127.0.0.1:11434/v1",
           model = "codellama",
           parse_curl_args = function(opts, code_opts)
             return {
               url = opts.endpoint .. "/chat/completions",
               headers = {
                 ["Accept"] = "application/json",
                 ["Content-Type"] = "application/json",
               },
               body = {
                 model = opts.model,
                 messages = require("avante.providers").copilot.parse_message(code_opts), -- you can make your own message, but this is very advanced
                 max_tokens = 2048,
                 stream = true,
               },
             }
           end,
           parse_response_data = function(data_stream, event_state, opts)
             require("avante.providers").openai.parse_response(data_stream, event_state, opts)
           end,
         },
       },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = vim.g.isWindowsOs and "pwsh -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
