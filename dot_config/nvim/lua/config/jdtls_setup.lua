local M = {}
function M.setup()
    local java_version = vim.fn.system("java -version 2>&1")
    local major_version = tonumber(java_version:match('version "(%d+)'))
    if not major_version or major_version < 21 then
        vim.notify(
            "Current eclipse.jdt.ls requires Java 21 or newer. Found: "
                .. (major_version and ("Java " .. major_version) or "an unknown Java version"),
            vim.log.levels.ERROR,
            { title = "Java LSP" }
        )
        return
    end

    local root_dir = vim.fs.root(0, {
        "mvnw",
        "gradlew",
        "settings.gradle",
        "settings.gradle.kts",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        ".git",
    }) or vim.fn.getcwd()
    local project_name = vim.fn.fnamemodify(root_dir, ":t")
    local workspace_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "jdtls-workspace", project_name)

    local function jars(pattern)
        return vim.fn.glob(pattern, true, true)
    end

    local bundles = jars(vim.fs.joinpath(
        vim.g.mason_root,
        "packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
    ))
    local excluded_test_jars = {
        ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
        ["jacocoagent.jar"] = true,
    }
    for _, jar in ipairs(jars(vim.fs.joinpath(
        vim.g.mason_root,
        "packages/java-test/extension/server/*.jar"
    ))) do
        if not excluded_test_jars[vim.fn.fnamemodify(jar, ":t")] then
            table.insert(bundles, jar)
        end
    end

    -- See `:help vim.lsp.start` for an overview of the supported `config` options.
    local config = {
        name = "jdtls",


        -- `cmd` defines the executable to launch eclipse.jdt.ls.
        -- `jdtls` must be available in $PATH and you must have Python3.9 for this to work.
        --
        -- As alternative you could also avoid the `jdtls` wrapper and launch
        -- eclipse.jdt.ls via the `java` executable
        -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
        cmd = {
            "jdtls",
            "-data",
            workspace_dir,
        },


        -- `root_dir` must point to the root of your project.
        -- See `:help vim.fs.root`
        root_dir = root_dir,


        -- Here you can configure eclipse.jdt.ls specific settings
        -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
        -- for a list of options
        settings = {
            java = {},
        },


        -- This sets the `initializationOptions` sent to the language server
        -- If you plan on using additional eclipse.jdt.ls plugins like java-debug
        -- you'll need to set the `bundles`
        --
        -- See https://codeberg.org/mfussenegger/nvim-jdtls#java-debug-installation
        --
        -- If you don't plan on any eclipse.jdt.ls plugins you can remove this
        init_options = {
            bundles = bundles,
        },

        on_attach = function()
            local jdtls = require("jdtls")
            jdtls.setup_dap({ hotcodereplace = "auto" })
            jdtls.setup.add_commands()
        end,
    }
    require("jdtls").start_or_attach(config)
end

return M
