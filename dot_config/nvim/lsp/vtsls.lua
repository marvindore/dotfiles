local function get_tsdk(root_dir)
  local local_tsdk = root_dir .. "/node_modules/typescript/lib"
  if vim.uv.fs_stat(local_tsdk) then
    return local_tsdk
  end

  local pnpm_root = vim.fn.system("pnpm root -g"):gsub("%s+$", "")
  local global_tsdk = pnpm_root .. "/typescript/lib"
  if vim.uv.fs_stat(global_tsdk) then
    return global_tsdk
  end

  return nil
end

local mason_vtsls = vim.fn.stdpath("data") .. "/mason/bin/vtsls"

return {
  cmd = { mason_vtsls, "--stdio" },

  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    -- astro can stay if you want, but vtsls doesn't handle it natively
    "astro",
  },

  root_dir = function(bufnr)
    return vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
  end,

  -- ✅ compute tsdk per buffer
  init_options = function(bufnr)
    local root = vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
    if not root then
      error("vtsls: root_dir not found for buffer " .. bufnr)
    end

    local tsdk = get_tsdk(root)
    if not tsdk then
      error("vtsls: TypeScript SDK not found in " .. root)
    end

    return {
      typescript = {
        tsdk = tsdk,
      },
    }
  end,
}
