-- Tree-sitter parser list.
-- Shared by plugins/treesitter.lua and the chezmoi headless bootstrap
-- (.chezmoiscripts/run_onchange_after_14-nvim-bootstrap.sh.tmpl), which
-- reruns when this file changes.
local langs = {
  "bash",
  "cmake",
  "comment",
  "css",
  "cuda",
  "dockerfile",
  "gitignore",
  "graphql",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "latex",
  "lua",
  "make",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "scss",
  "sql",
  "svelte",
  "todotxt",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "yaml",
}

-- Feature-flagged languages (flags are set in lua/globals.lua).
local optional = {
  { flag = "enableRust",   langs = { "rust" } },
  { flag = "enableJava",   langs = { "java", "kotlin" } },
  { flag = "enableCsharp", langs = { "c_sharp" } },
  { flag = "enableGo",     langs = { "go", "gomod", "gowork" } },
}
for _, o in ipairs(optional) do
  if vim.g[o.flag] then vim.list_extend(langs, o.langs) end
end

return langs
