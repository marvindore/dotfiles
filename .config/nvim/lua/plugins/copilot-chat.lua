local prompts = {
  -- Code related prompts
  Explain = "Please explain how the following code works.",
  Review = "Please review the following code and provide suggestions for improvement.",
  Tests = "Please explain how the selected code works, then generate unit tests for it.",
  Refactor = "Please refactor the following code to improve its clarity and readability.",
  FixCode = "Please fix the following code to make it work as intended.",
  FixError = "Please explain the error in the following text and provide a solution.",
  BetterNamings = "Please provide better names for the following variables and functions.",
  Documentation = "Please provide documentation for the following code.",
  SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
  SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
  -- Text related prompts
  Summarize = "Please summarize the following text.",
  Spelling = "Please correct any grammar and spelling errors in the following text.",
  Wording = "Please improve the grammar and wording of the following text.",
  Concise = "Please rewrite the following text to make it more concise.",
}

return {
  "CopilotC-Nvim/CopilotChat.nvim",
  cmd = "CopilotChatToggle",
  enabled = vim.g.enableCopilot,
  branch = "canary",
  -- tag = "v2.6.2",
  -- cmd = "CopilotChat",
  -- branch = "canary", -- Use the canary branch if you want to test the latest features but it might be unstable
  -- Do not use branch and version together, either use branch or version
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim" },
  },
  opts = {
    question_header = "## User ",
    answer_header = "## Copilot ",
    error_header = "## Error ",
    separator = " ",            -- Separator to use in chat
    prompts = prompts,
    auto_follow_cursor = false, -- Don't follow the cursor after getting response
    show_help = false,          -- Show help in virtual text, set to true if that's 1st time using Copilot Chat
    mappings = {
      -- Use tab for completion
      complete = {
        detail = "Use @<Tab> or /<Tab> for options.",
        insert = "<Tab>",
      },
      -- Close the chat
      close = {
        normal = "q",
        insert = "<C-c>",
      },
      -- Reset the chat buffer
      reset = {
        normal = "<C-l>",
        insert = "<C-l>",
      },
      -- Submit the prompt to Copilot
      submit_prompt = {
        normal = "<CR>",
        insert = "<C-CR>",
      },
      -- Accept the diff
      accept_diff = {
        normal = "<C-y>",
        insert = "<C-y>",
      },
      -- Yank the diff in the response to register
      yank_diff = {
        normal = "gmy",
      },
      -- Show the diff
      show_diff = {
        normal = "gmd",
      },
      -- Show the prompt
      show_system_prompt = {
        normal = "gmp",
      },
      -- Show the user selection
      show_user_selection = {
        normal = "gms",
      },
    },
  },
  config = function(_, opts)
    local chat = require("CopilotChat")
    local select = require("CopilotChat.select")
    -- Use unnamed register for the selection
    opts.selection = select.unnamed

    -- Override the git prompts message
    opts.prompts.Commit = {
      prompt = "Write commit message for the change with commitizen convention",
      selection = select.gitdiff,
    }
    opts.prompts.CommitStaged = {
      prompt = "Write commit message for the change with commitizen convention",
      selection = function(source)
        return select.gitdiff(source, true)
      end,
    }

    chat.setup(opts)

    vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
      chat.ask(args.args, { selection = select.visual })
    end, { nargs = "*", range = true })

    -- Inline chat with Copilot
    vim.api.nvim_create_user_command("CopilotChatInline", function(args)
      chat.ask(args.args, {
        selection = select.visual,
        window = {
          layout = "float",
          relative = "cursor",
          width = 1,
          height = 0.4,
          row = 1,
        },
      })
    end, { nargs = "*", range = true })

    -- Restore CopilotChatBuffer
    vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
      chat.ask(args.args, { selection = select.buffer })
    end, { nargs = "*", range = true })

    -- Custom buffer for CopilotChat
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-*",
      callback = function()
        vim.opt_local.relativenumber = true
        vim.opt_local.number = true

        -- Get current filetype and set it to markdown if the current filetype is copilot-chat
        local ft = vim.bo.filetype
        if ft == "copilot-chat" then
          vim.bo.filetype = "markdown"
        end
      end,
    })

    -- Add which-key mappings
    local wk = require("which-key")
    wk.register({
      g = {
        m = {
          name = "+Copilot Chat",
          d = "Show diff",
          p = "System prompt",
          s = "Show selection",
          y = "Yank diff",
        },
      },
    })
  end,
  keys = {},
}
