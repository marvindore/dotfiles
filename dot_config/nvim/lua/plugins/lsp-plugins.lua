local mason = require("plugins.lsp.mason")
local lsp_javascript = require("plugins.lsp.lsp-javascript")
local lsp_csharp = require("plugins.lsp.lsp-csharp")
local lsp_java = require("plugins.lsp.lsp-java")
local rustacean = require("plugins.lsp.rustacean")
local rustvim = require("plugins.lsp.rustvim")

return {
  mason,
  lsp_csharp,
  lsp_java,
  lsp_javascript,
  rustacean,
  rustvim
}
