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

  local npm_root = vim.fn.system("npm root -g"):gsub("%s+$", "")
  local npm_global_tsdk = npm_root .. "/typescript/lib"
  if vim.uv.fs_stat(npm_global_tsdk) then
    return npm_global_tsdk
  end

  return nil
end

local mason_vtsls = vim.fn.stdpath("data") .. "/mason/bin/vtsls"

return function(bufnr)
  -- ✅ Detect root using native API
  local root = vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
  if not root then
    return nil -- Do NOT start if no root found
  end

  local tsdk = get_tsdk(root)
  if not tsdk then
    return nil -- Do NOT start if no TypeScript SDK found
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
    root_dir = root, -- ✅ Explicitly set root
    init_options = {
      typescript = {
        tsdk = tsdk,
      },
    },
  }
end
