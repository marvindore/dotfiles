local function get_tsdk()
  local root_dir = vim.fn.getcwd()
  local local_tsdk = root_dir .. "/node_modules/typescript/lib"
  if vim.uv.fs_stat(local_tsdk) then
    return local_tsdk
  end

  local pnpm_root = vim.fn.system("pnpm root -g"):gsub("%s+$", "")
  local global_tsdk = pnpm_root .. "/typescript/lib"
  if vim.uv.fs_stat(global_tsdk) then
    return global_tsdk
  end

  local npm_root = vim.fn.system("npm root -g"):gsub("%s+$", "")
  local npm_global_tsdk = npm_root .. "/typescript/lib"
  if vim.uv.fs_stat(npm_global_tsdk) then
    return npm_global_tsdk
  end

  return nil
end

-- 🔍 Utility that finds typescript-plugin-css-modules
local function get_css_modules_plugin()
  local cwd = vim.fn.getcwd()

  -- 1) Check local project installation
  local local_path = cwd .. "/node_modules/typescript-plugin-css-modules"
  if vim.uv.fs_stat(local_path) then
    return local_path
  end

  -- 2) Check global pnpm installation
  local pnpm_root = vim.fn.system("pnpm root -g"):gsub("%s+$", "")
  local pnpm_global_path = pnpm_root .. "/typescript-plugin-css-modules"
  if vim.uv.fs_stat(pnpm_global_path) then
    return pnpm_global_path
  end

  -- 3) Check global npm installation
  local npm_root = vim.fn.system("npm root -g"):gsub("%s+$", "")
  local npm_global_path = npm_root .. "/typescript-plugin-css-modules"
  if vim.uv.fs_stat(npm_global_path) then
    return npm_global_path
  end

  -- Nothing found
  return nil
end

local mason_vtsls = vim.fn.stdpath("data") .. "/mason/bin/vtsls"
local tsdk = get_tsdk()
local css_plugin_path = get_css_modules_plugin()

-- Construct plugin entry dynamically
local css_plugin = {
  name = "typescript-plugin-css-modules",
  enableForWorkspaceTypeScriptVersions = true,
}

-- Attach location only if found
if css_plugin_path then
  css_plugin.location = css_plugin_path
end

return {
  cmd = { mason_vtsls, "--stdio" },

  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "astro",
  },

  init_options = {
    typescript = {
      tsdk = tsdk,
    },
  },

  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = { css_plugin },
      },
    },

    typescript = {
      preferences = {
        importModuleSpecifier = "non-relative",
        quoteStyle = "single",
      },
      inlayHints = {
        includeInlayParameterNameHints = "literals",
        includeInlayVariableTypeHints = true,
      },
    },

    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "literals",
        includeInlayVariableTypeHints = true,
      },
    },
  },
}
