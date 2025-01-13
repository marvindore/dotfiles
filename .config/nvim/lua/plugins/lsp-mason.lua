local utils = require("utils")

local roslyn_setup_keymaps = function()
  vim.keymap.set(
    "n",
    "<leader>itp",
    "<cmd>lua require('easy-dotnet').test_project()<cr>",
    { buffer = 0, desc = "Dotnet test project" }
  )
  vim.keymap.set(
    "n",
    "<leader>itd",
    "<cmd>lua require('easy-dotnet').test_default()<cr>",
    { buffer = 0, desc = "Dotnet test default" }
  )
  vim.keymap.set(
    "n",
    "<leader>its",
    "<cmd>lua require('easy-dotnet').test_solution()<cr>",
    { buffer = 0, desc = "Dotnet test solution" }
  )
  vim.keymap.set(
    "n",
    "<leader>irp",
    "<cmd>lua require('easy-dotnet').run_project()<cr>",
    { buffer = 0, desc = "Dotnet run project" }
  )
  vim.keymap.set(
    "n",
    "<leader>irP",
    "<cmd>lua require('easy-dotnet').run_with_profile(false)<cr>",
    { buffer = 0, desc = "Dotnet run profile" }
  )
  vim.keymap.set(
    "n",
    "<leader>ird",
    "<cmd>lua require('easy-dotnet').run_default()<cr>",
    { buffer = 0, desc = "Dotnet run default" }
  )
  vim.keymap.set(
    "n",
    "<leader>ire",
    "<cmd>lua require('easy-dotnet').restore()<cr>",
    { buffer = 0, desc = "Dotnet restore" }
  )
  vim.keymap.set(
    "n",
    "<leader>ise",
    "<cmd>lua require('easy-dotnet').secrets()<cr>",
    { buffer = 0, desc = "Dotnet serets" }
  )
  vim.keymap.set(
    "n",
    "<leader>ibp",
    "<cmd>lua require('easy-dotnet').build()<cr>",
    { buffer = 0, desc = "Dotnet build project" }
  )
  vim.keymap.set(
    "n",
    "<leader>ibd",
    "<cmd>lua require('easy-dotnet').build_default()<cr>",
    { buffer = 0, desc = "Dotnet build default" }
  )
  vim.keymap.set(
    "n",
    "<leader>ibs",
    "<cmd>lua require('easy-dotnet').build_solution()<cr>",
    { buffer = 0, desc = "Dotnet build solution" }
  )
  vim.keymap.set(
    "n",
    "<leader>ibq",
    "<cmd>lua require('easy-dotnet').build_quickfix()<cr>",
    { buffer = 0, desc = "Dotnet build quickfix" }
  )
  vim.keymap.set(
    "n",
    "<leader>ibQ",
    "<cmd>lua require('easy-dotnet').build_default_quickfix()<cr>",
    { buffer = 0, desc = "Dotnet build default quickfix" }
  )
  vim.keymap.set(
    "n",
    "<leader>icp",
    "<cmd>lua require('easy-dotnet').clean()<cr>",
    { buffer = 0, desc = "Dotnet clean project" }
  )
  vim.keymap.set(
    "n",
    "<leader>idd",
    "<cmd>lua require('easy-dotnet').get_debug_dll()<cr>",
    { buffer = 0, desc = "Dotnet get debug dll" }
  )
  vim.keymap.set(
    "n",
    "<leader>idp",
    "<cmd>lua require('easy-dotnet').is_dotnet_project()<cr>",
    { buffer = 0, desc = "Dotnet is project" }
  )
end

return { -- LSP Configuration & Plugins
  "neovim/nvim-lspconfig",
  opts = {
    --inlay_hints = { enabled = true },
  },
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- LSP
    {
      "seblj/roslyn.nvim",
      enabled = utils.enableCsharp
    },
    "nvim-lua/lsp-status.nvim",
    {
      "j-hui/fidget.nvim",
      tag = "legacy",
      event = "LspAttach",
    },
    {
      "nvim-java/nvim-java",
      event = { "BufEnter *.java" },
      enabled = utils.enableJava,
      dependencies = {
        "nvim-java/lua-async-await",
        "nvim-java/nvim-java-core",
        "nvim-java/nvim-java-test",
        "nvim-java/nvim-java-dap",
        "MunifTanjim/nui.nvim",
        "neovim/nvim-lspconfig",
        "mfussenegger/nvim-dap",
        {
          "williamboman/mason.nvim",
          opts = {
            registries = {
              "github:nvim-java/mason-registry",
              "github:mason-org/mason-registry",
            },
          },
        },
      },
      config = function()
        require("java").setup()
        local lspconfig = require("lspconfig")
        local home = require("utils").home
        lspconfig.jdtls.setup({
          settings = {
            java = {
              configuration = {
                runtimes = {
                  {
                    name = "JavaSE-21",
                    path = home .. "/.asdf/installs/java/zulu-21.38.21",
                    default = true,
                  },
                },
              },
            },
          },
        })
      end,
    }
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local home = require("utils").home
    local util = require("lspconfig.util")
    local pid = vim.fn.getpid()

    -- lsp_signature
    local on_attach_lsp_signature = function(client, bufnr)
      -- https://github.com/ray-x/lsp_signature.nvim#full-configuration-with-default-values
      require("lsp_signature").on_attach({
        bind = true, -- This is mandatory, otherwise border config won't get registered.
        floating_window = true,
        handler_opts = {
          border = "single",
        },
        zindex = 99,      -- <100 so that it does not hide completion popup.
        fix_pos = false,  -- Let signature window change its position when needed, see GH-53
        toggle_key = "<M-x>", -- Press <Alt-x> to toggle signature on and off.
      })
    end

    -- Specify how the border looks like
    local border = {
      { "┌", "FloatBorder" },
      { "─", "FloatBorder" },
      { "┐", "FloatBorder" },
      { "│", "FloatBorder" },
      { "┘", "FloatBorder" },
      { "─", "FloatBorder" },
      { "└", "FloatBorder" },
      { "│", "FloatBorder" },
    }

    -- Add the border on hover and on signature help popup window
    local handlers = {
      ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
      ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
    }

    -- Add border to the diagnostic popup window
    -- vim.diagnostic.config({
    -- 	virtual_text = {
    -- 		prefix = "■ ", -- Could be '●', '▎', 'x', '■', , 
    -- 	},
    -- 	float = { border = border },
    -- })

    -------------------------------------------
    --- diagnostics: linting and formatting ---
    -------------------------------------------
    vim.diagnostic.config({
      virtual_text = {
        source = true,
        prefix = "●",
      },
      underline = false,
      signs = true,
      severity_sort = true,
      float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
        focusable = false,
      },
    })
    -- LSP settings.
    --  This function gets run when an LSP connects to a particular buffer.
    _G.on_attach = function(server_name)
      return function(client, bufnr)
        -- Create a command `:Format` local to the LSP buffer
        -- Set keymaps here so they only pertain to buffers that a lang server attaches too
        -- buffer=0 means only set for current buffer
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          if vim.lsp.buf.format then
            vim.lsp.buf.format()
          elseif vim.lsp.buf.formatting then
            vim.lsp.buf.formatting()
          end
        end, { desc = "Format current buffer with LSP" })

        -- if client.server_capabilities.inlayHintProvider then
        -- 	vim.lsp.inlay_hint.enable(true)
        -- end
        -- toggle inlay hints
        vim.g.inlay_hints_visible = false
        local function toggle_inlay_hints()
          if vim.g.inlay_hints_visible then
            vim.g.inlay_hints_visible = false
            vim.lsp.inlay_hint.enable(false)
          else
            if client.server_capabilities.inlayHintProvider then
              vim.g.inlay_hints_visible = true
              vim.lsp.inlay_hint.enable(true)
            else
              print("no inlay hints available")
            end
          end
        end

        --- toggle diagnostics
        vim.g.diagnostics_visible = true
        local function toggle_diagnostics()
          if vim.g.diagnostics_visible then
            vim.g.diagnostics_visible = false
            vim.diagnostic.enable(false)
          else
            vim.g.diagnostics_visible = true
            vim.diagnostic.enable()
          end
        end

        --- autocmd to show diagnostics on CursorHold
        vim.api.nvim_create_autocmd("CursorHold", {
          buffer = bufnr,
          desc = "✨lsp show diagnostics on CursorHold",
          callback = function()
            local hover_opts = {
              focusable = false,
              close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
              border = "rounded",
              source = "always",
              prefix = " ",
            }
            vim.diagnostic.open_float(nil, hover_opts)
          end,
        })

        vim.keymap.set(
          "n",
          "<leader>dh",
          toggle_inlay_hints,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp toggle inlay hints" })
        )
        vim.keymap.set(
          "n",
          "<leader>l",
          toggle_diagnostics,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp toggle diagnostics" })
        )
        ---
        on_attach_lsp_signature(client, bufnr)

        vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", { buffer = 0 })
        vim.keymap.set(
          "n",
          "gd",
          "<cmd>lua vim.lsp.buf.definition()<cr>",
          { buffer = 0, desc = "LSP Go To Definition" }
        )
        vim.keymap.set(
          "n",
          "gt",
          "<cmd>lua vim.lsp.buf.type_definition()<cr>",
          { buffer = 0, desc = "LSP Go to Type Definition" }
        )
        vim.keymap.set(
          "n",
          "gi",
          "<cmd>lua vim.lsp.buf.implementation()<cr>",
          { buffer = 0, desc = "LSP Go to implementation" }
        )
        vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<cr>", {
          buffer = 0,
          desc = "LSP Telescope diagnostics",
        })
        vim.keymap.set("n", "rn", ":lua vim.lsp.buf.rename()<cr>", { buffer = 0, desc = "LSP Rename Variable" })
        vim.keymap.set(
          "n",
          "gc",
          ":lua vim.lsp.buf.code_action()<cr>",
          { buffer = 0, desc = "LSP Code action" }
        )
        vim.keymap.set(
          "n",
          "gD",
          ":lua vim.lsp.buf.declaration()<cr>",
          { buffer = 0, desc = "LSP Go To Declaration" }
        )
        vim.keymap.set(
          "n",
          "gr",
          ":lua require('telescope.builtin').lsp_references()<cr>",
          { buffer = 0, desc = "LSP Telescope Find References" }
        )
        vim.keymap.set(
          "n",
          "gR",
          ":lua vim.lsp.buf.references()<cr>",
          { buffer = 0, desc = "LSP Find References" }
        )
        vim.keymap.set(
          "n",
          "gs",
          ":lua vim.lsp.buf.signature_help()<cr>",
          { buffer = 0, desc = "LSP Signature" }
        )
        -- Lesser used LSP functionality
        vim.keymap.set("n", "<leader>wa", ":lua vim.lsp.buf.add_workspace_folder()<cr>")
        vim.keymap.set("n", "<leader>wr", ":lua vim.lsp.buf.remove_workspace_folder()<cr>")
        --Diagnostic keymaps
        vim.keymap.set(
          "n",
          "[d",
          "<cmd>vim.diagnostic.goto_prev()<cr>",
          { buffer = 0, desc = "Go to prev diagnostic" }
        )
        vim.keymap.set(
          "n",
          "]d",
          "<cmd>vim.diagnostic.goto_next()<cr>",
          { buffer = 0, desc = "Go to next diagnostic" }
        )
        vim.keymap.set(
          "n",
          "<LocalLeader>do",
          "<cmd>vim.diagnostic.open_float()<cr>",
          { buffer = 0, desc = "Diagnostics open float" }
        )
        vim.keymap.set(
          "n",
          "<leader>q",
          "<cmd>vim.diagnostic.setloclist()<cr>",
          { buffer = 0, desc = "Set loc list" }
        )
        -- vim.keymap.set(
        -- 	"n",
        -- 	"<LocalLeader>dh",
        -- 	":lua vim.diagnostic.hide()<CR>",
        -- 	{ buffer = 0, desc = "Hide diagnostics" }
        -- )
        -- vim.keymap.set(
        -- 	"n",
        -- 	"<LocalLeader>ds",
        -- 	":lua vim.diagnostic.show()<CR>",
        -- 	{ buffer = 0, desc = "Show diagnostics" }
        -- )
        vim.keymap.set(
          "n",
          "<leader>ls",
          ":lua require('telescope.builtin').lsp_document_symbols()<cr>",
          { buffer = 0, desc = "LSP document symbol" }
        )
        vim.keymap.set(
          "n",
          "<leader>ws",
          ":lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>",
          { buffer = 0, desc = "LSP workspace symbol" }
        )

        -- Goto Preview
        vim.keymap.set(
          "n",
          "gpd",
          "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
          { buffer = 0, desc = "Definition - Goto preview " }
        )
        vim.keymap.set(
          "n",
          "gpt",
          "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
          { buffer = 0, desc = "Type - Goto preview " }
        )
        vim.keymap.set(
          "n",
          "gpi",
          "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>",
          { buffer = 0, desc = "Implementation - Goto preview " }
        )
        vim.keymap.set(
          "n",
          "gpD",
          "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>",
          { buffer = 0, desc = "Declaration - Goto preview " }
        )
        vim.keymap.set(
          "n",
          "gpc",
          "<cmd>lua require('goto-preview').close_all_win()<CR>",
          { buffer = 0, desc = "Close - Goto preview " }
        )
        vim.keymap.set(
          "n",
          "gpr",
          "<cmd>lua require('goto-preview').goto_preview_references()<CR>",
          { buffer = 0, desc = "References - Goto preview " }
        )

        if server_name == "jdtls" then
          vim.keymap.set(
            "n",
            "<leader>dvc",
            "<cmd>lua require('jdtls').test_class()<cr>",
            { buffer = 0, desc = "Java Test Class" }
          )
          vim.keymap.set(
            "n",
            "<leader>dvm",
            "<cmd>lua require('jdtls').test_nearest_method()<cr>",
            { buffer = 0, desc = "Java Test Nearest Method" }
          )
        end

        if server_name == "ts_ls" then
          client.server_capabilities.documentFormattingProvider = false
        end

        if server_name == "roslyn" then
          local wk = require("which-key")

          wk.add({
            { "<leader>i",  group = "IDE" },
            { "<leader>it", group = "IDE Test" },
            { "<leader>ir", group = "IDE Run" },
            { "<leader>is", group = "IDE Secrets" },
            { "<leader>ib", group = "IDE Build" },
            { "<leader>ic", group = "IDE Clean" },
            { "<leader>id", group = "IDE MSC" },
          })
          roslyn_setup_keymaps()
        end
      end
    end
    -- Mason path ~/.local/share/nvim/mason/bin
    -- END Keymaps to work outside of LSP
    local pid = vim.fn.getpid()
    local root_pattern = require("lspconfig.util").root_pattern
    local lspconfig = require("lspconfig")
    local configs = require("lspconfig.configs")

    local lsp_status = require("lsp-status")
    lsp_status.register_progress()

    -- Setup mason so it can manage external tooling
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    local ensure_installed = {
      "bashls",
      "cspell",
      "dockerls",
      "jsonls",
      "lemminx",
      "lua_ls",
      "tailwindcss",
      "yamlls",
      "sqlls",
      "stylua",
      "vale",
    }

    -- Enable the following language servers
    -- Feel free to add/remove any LSPs that you want here. They will automatically be installed
    local lsp_servers = {
      "bashls",
      "dockerls",
      "lemminx",
      "lua_ls",
      "sqlls",
      "yamlls",
    }

    if utils.enableCsharp then
      local cSharp_addons = {
        "csharpier",
        "netcoredbg",
      }

      for _, value in ipairs(cSharp_addons) do
        table.insert(ensure_installed, value)
      end
    end

    if utils.enableGo then
      local go_addons = {
        "gopls",
        "delve",
      }

      local go_servers = { "gopls" }
      for _, value in ipairs(go_servers) do
        table.insert(lsp_servers, value)
      end
    end

    if utils.enableJava then
      local java_addons = {

        "java-debug-adapter",
        "java-test",
        "jdtls",
      }
      local java_servers = { "jdtls" }

      for _, value in ipairs(java_servers) do
        table.insert(lsp_servers, value)
      end
    end

    if utils.enableJavascript then
      local javascript_servers = {
        "angularls",
        "astro",
        "biome",
        "eslint",
      	"jsonls",
      "tailwindcss",
      }
      local javascript_addons = {
        "angularls",
        "astro",
        "biome",
        "eslint",
        "prettier",
        "js-debug-adapter",
        "ts_ls",
      }

      for _, value in ipairs(javascript_servers) do
        table.insert(lsp_servers, value)
      end
    end

    if utils.enablePython then
      local python_servers = {
        "pyright",
      }

      local python_addons = {

        "black",
        "flake8",
        "pyright",
      }

      for _, value in ipairs(python_servers) do
        table.insert(lsp_servers, value)
      end
    end

    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
      auto_update = false,
      run_on_start = false,
    })

    -- Ensure the servers above are installed
    require("mason-lspconfig").setup({
      ensure_installed = lsp_servers,
    })

    -- nvim-cmp supports additional completion capabilities, broadcast that to servers
    local capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require("cmp_nvim_lsp").default_capabilities()
    )

    -- in 0.9 neovim doesn't enable watch mechanism by default, lsp doesn't get notified of changes outside of nvim
    capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

    for _, lsp in ipairs(lsp_servers) do
      lspconfig[lsp].setup({
        on_attach = _G.on_attach(lsp),
        handlers = handlers,
        capabilities = capabilities,
      })
    end

    -- Turn on lsp status information
    require("fidget").setup()

    vim.api.nvim_create_autocmd("User", {
      pattern = "MasonToolsUpdateCompleted",
      callback = function()
        vim.schedule(function()
          print("mason-tool-installer has finished")
        end)
      end,
    })

    -- Make runtime files discoverable to the server
    local runtime_path = vim.split(package.path, ";")
    table.insert(runtime_path, "lua/?.lua")
    table.insert(runtime_path, "lua/?/init.lua")

    lspconfig.lua_ls.setup({
      on_attach = _G.on_attach("lua_ls"),
      capabilities = capabilities,
      handlers = handlers,
      settings = {
        Lua = {
          runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT)
            version = "LuaJIT",
            -- Setup your lua path
            path = runtime_path,
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          -- Do not send telemetry data containing a randomized but unique identifier
          telemetry = { enable = false },
        },
      },
    })

    if utils.enableCsharp then
      require("roslyn").setup({
        config = {
          on_attach = _G.on_attach("roslyn"),
          handlers = handlers,
          capabilities = capabilities,
          cmd = {
            "dotnet",
            vim.fs.joinpath(vim.fn.stdpath("data"), "roslyn", "Microsoft.CodeAnalysis.LanguageServer.dll"),
          },
          settings = {
            ["csharp|inlay_hints"] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
          },
        },
      })
    end

    lspconfig.sqls.setup({
      on_attach = _G.on_attach("sqls"),
      capabilities = capabilities,
      handlers = handlers,
      cmd = {
        utils.isWindows and utils.neovim_home .. "/mason/packages/sqls/sqls.exe"
        or utils.neovim_home .. "/mason/bin/sqls",
        "--config",
        utils.home .. "/.config/sqls.yml",
      },
      -- root_dir = function(fname)
      --   return root_pattern(fname) or vim.loop_os_homedir()
      -- end
    })

    lspconfig.ts_ls.setup({
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "typescript.tsx" },
      root_dir = util.root_pattern("package.json"),
      handlers = handlers,
      on_attach = _G.on_attach("ts_ls"),
      capabilities = capabilities,
      init_options = {
        preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
          importModuleSpecifierPreference = "non-relative",
        },
      },
    })

    -- For debugging you must install delve https://www.youtube.com/watch?v=i04sSQjd-qo
    lspconfig.gopls.setup({
      on_attach = _G.on_attach("gopls"),
      capabilities = capabilities,
      handlers = handlers,
      cmd = { "gopls" },
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
      root_dir = root_pattern("go.work", "go.mod", ".git"),
      settings = {
        gopls = {
          completeUnimported = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
        },
      },
    })

    -------------------
    --- lsp logging ---
    -------------------
    vim.lsp.set_log_level("off")
  end,
}
