return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
  ft = { "cs", "razor" },
  -- Tell lazy to load when this command is run
  cmd = { "Secrets" },
  -- Tell lazy to load when this key is pressed
  keys = {
    {
      "<C-p>",
      function()
        require("easy-dotnet").run_project()
      end,
      desc = "Run Dotnet Project",
    },
  },
  enabled = vim.g.enableCsharp,
  config = function()
    local function get_secret_path(secret_guid)
      local path = ""
      local home_dir = vim.fn.expand("~")
      if require("easy-dotnet.extensions").isWindows() then
        local secret_path = home_dir
          .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
          .. secret_guid
          .. "\\secrets.json"
        path = secret_path
      else
        local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
        path = secret_path
      end
      return path
    end

    local dotnet = require("easy-dotnet")
    
    dotnet.setup({
      get_sdk_path = require("easy-dotnet.extensions").isWindows() and vim.fn.expand("~") .. "" or vim.fn.expand("~") .. "/.asdf/shims/dotnet",
      test_runner = {
        viewmode = "split",
        noBuild = true,
        noRestore = true,
      },
      terminal = function(path, action)
        local commands = {
          run = function() return "dotnet run --project " .. path end,
          test = function() return "dotnet test " .. path end,
          restore = function() return "dotnet restore " .. path end,
          build = function() return "dotnet build " .. path end,
        }
        local command = commands[action]() .. "\r"
        vim.cmd("vsplit")
        vim.cmd("term " .. command)
      end,
      secrets = {
        path = get_secret_path,
      },
      csproj_mappings = true,
      fsproj_mappings = true,
      auto_bootstrap_namespace = {
        type = "block_scoped",
        enabled = true,
      },
      picker = "snacks",
    })

    -- We define the command here so it actually executes after Lazy loads the plugin
    vim.api.nvim_create_user_command("Secrets", function()
      dotnet.secrets()
    end, {})
  end,
}
