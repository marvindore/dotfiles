-- Example: ~/.config/nvim/ftplugin/java.lua
local config = {
    cmd = {'java', '-Declipse.application=org.eclipse.jdt.ls.core.id1', '-Dosgi.bundles.defaultStartLevel=4', '-Declipse.product=org.eclipse.jdt.ls.core.product', '-Dlog.protocol=true', '-Dlog.level=ALL', '-Xmx1g', '--add-modules=ALL-SYSTEM', '--add-opens', 'java.base/java.util=ALL-UNNAMED', '--add-opens', 'java.base/java.lang=ALL-UNNAMED', '-jar', '/path/to/jdtls/plugins/org.eclipse.equinox.launcher_...jar', '-configuration', '/path/to/jdtls/config_mac', '-data', vim.fn.expand('~/.cache/jdtls-workspace') .. '/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')},
    root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
}
require('jdtls').start_or_attach(config)
