# Building Your First Neovim Plugin: The "CLI Context Bridge"

Welcome! By the end of this guide, you will have created a plugin that bridges the gap between your Neovim editor and official AI CLIs (like Claude Code or Gemini CLI). You will learn how to manipulate terminal buffers, interact with the Neovim API, and structure a project for portability.

---

## 1. The Anatomy of a Neovim Plugin

Neovim looks for plugins in your `runtimepath`. Modern plugins follow a standard directory structure:

```text
my-plugin/
├── lua/
│   └── my-plugin/
│       ├── init.lua      # The entry point (where setup() lives)
│       └── terminal.lua  # Modularized logic (e.g., terminal handling)
└── plugin/
    └── my-plugin.lua     # Files here run automatically on startup
```

### Why this structure?
- **`lua/`**: This is where your logic lives. Files here are not run automatically; they must be "required" (`require('my-plugin')`).
- **`plugin/`**: Files here are "sourced" (run) every time Neovim starts. We use this to register user commands (like `:Claude`) or default keymaps.

---

## 2. Setting Up Your Workspace

Since you use `chezmoi`, we will create this plugin in a local folder first so you can test it live.

1. Create the directory: `mkdir -p ~/projects/cli-bridge.nvim/lua/cli-bridge`
2. Open Neovim in that folder.

---

## 3. The Core Concept: "The Bridge"

To build this plugin, we need to solve three technical problems:
1. **The Job ID**: Every terminal in Neovim has a `job_id`. To send text to a terminal, we need that ID.
2. **Context Retrieval**: How do we get the filename or the selected text?
3. **Piping**: How do we send that text to the terminal without "pasting" (which is slow and can break formatting)?

### The Secret Weapon: `vim.api.nvim_chan_send`
This is the most important function you will learn. Unlike "pasting," which simulates a user typing, `nvim_chan_send` writes directly to the input stream of the process running in the terminal.

---

## 4. Step-by-Step Implementation

### Step 4.1: The Entry Point (`lua/cli-bridge/init.lua`)
This file defines how other users will configure your plugin.

```lua
local M = {}

-- Default configuration
M.config = {
    cmd = "claude", -- Default CLI to run
    terminal_style = "split", -- 'split' or 'vsplit'
}

function M.setup(user_opts)
    -- Merge user options with defaults
    M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})
end

return M
```

### Step 4.2: Terminal Logic (`lua/cli-bridge/terminal.lua`)
We need a way to track the AI terminal and send text to it.

```lua
local M = {}
local terminal_buf = nil
local terminal_job_id = nil

function M.open_terminal()
    -- Check if terminal buffer still exists and is valid
    if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
        -- If it exists, just switch to it
        vim.cmd("buffer " .. terminal_buf)
    else
        -- Create a new split
        vim.cmd("split | term " .. require('cli-bridge').config.cmd)
        terminal_buf = vim.api.nvim_get_current_buf()
        terminal_job_id = vim.b.terminal_job_id
    end
end

function M.send_context()
    -- 1. Get current file path relative to project root
    local path = vim.fn.expand("%:.")
    
    -- 2. Ensure terminal is open
    if not terminal_job_id then
        print("Error: AI Terminal not started. Run :AI first.")
        return
    end

    -- 3. Send the @ command
    -- \13 is the internal code for 'Enter'
    local text_to_send = "@" .. path .. " "
    vim.api.nvim_chan_send(terminal_job_id, text_to_send)
    
    print("Sent " .. path .. " to AI context.")
end

return M
```

---

## 5. Level Up: The "@" Interceptor (Intermediate)

To make it feel like a real IDE, we want to type `@` inside the terminal and have a file picker appear. This is where you move from "Beginner" to "Intermediate."

We will use **`vim.on_key`**. This allows us to listen to every keypress in Neovim.

```lua
-- Inside terminal.lua
function M.setup_interceptor()
    vim.on_key(function(key)
        -- If we are in the terminal buffer AND the key is '@'
        if vim.api.nvim_get_current_buf() == terminal_buf and key == "@" then
            -- Use schedule to avoid timing issues during key processing
            vim.schedule(function()
                -- Here you could trigger Telescope!
                -- require('telescope.builtin').find_files({
                --     attach_mappings = function(prompt_bufnr, map)
                --         -- Logic to send selected file to terminal
                --     end
                -- })
            end)
        end
    end)
end
```

---

## 6. How to Test Your Plugin

To test a plugin you are developing locally without installing it:

1. Open Neovim.
2. Run `:set runtimepath+=~/projects/cli-bridge.nvim`
3. Now you can run `:lua require('cli-bridge').setup()` and test your functions.

---

## 7. Essential API Glossary for your Journey

As you build more, you will live in these three areas of the Neovim manual (`:help`):

1. **`vim.api.*`**: The core "C-level" functions. Use this for manipulating buffers, windows, and sending text.
2. **`vim.fn.*`**: Access to legacy Vimscript functions (like `expand("%")` to get filenames).
3. **`vim.ui.*`**: For creating standard Neovim inputs and select menus.

### Your Next Assignment:
Try to modify `terminal.lua` so that if you have text **selected** in Visual Mode, hitting a keybind sends that block of code to the terminal wrapped in markdown code blocks (```` ``` ````).

**Hint:** Look up `vim.api.nvim_buf_get_text` to get the selection!
