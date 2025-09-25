local M = {}
local data_dir = vim.fn.stdpath 'data'
local jdtls_base = data_dir .. '/mason/packages/jdtls'
local lombok_jar = data_dir .. '/jdtls/lombok.jar'
local function workspace_dir()
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local ws = data_dir .. '/jdtls-workspace/' .. project_name
  vim.fn.mkdir(ws, 'p')
  return ws
end
M.cmd = function()
  local launcher = vim.fn.glob(jdtls_base .. '/plugins/org.eclipse.equinox.launcher_*.jar')
  local config_dir = (vim.loop.os_uname().sysname == 'Darwin') and (jdtls_base .. '/config_mac')
    or (vim.fn.has 'win32' == 1) and (jdtls_base .. '/config_win')
    or (jdtls_base .. '/config_linux')
  return {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-javaagent:' .. lombok_jar,
    '-Xbootclasspath/a:' .. lombok_jar,
    '-jar',
    launcher,
    '-configuration',
    config_dir,
    '-data',
    workspace_dir(),
  }
end
M.settings = {
  java = {
    configuration = { updateBuildConfiguration = 'interactive' },
    completion = {
      favoriteStaticMembers = {
        'org.mockito.Mockito.*',
        'org.hamcrest.MatcherAssert.*',
        'org.hamcrest.Matchers.*',
        'org.assertj.core.api.Assertions.*',
      },
    },
    contentProvider = { preferred = 'fernflower' },
    eclipse = { downloadSources = true },
    maven = { downloadSources = true },
    implementationsCodeLens = { enabled = true },
    referencesCodeLens = { enabled = true },
    references = { includeDecompiledSources = true },
    format = { enabled = true },
  },
}
M.on_attach = function(_, bufnr)
  local jdtls = require 'jdtls'
  jdtls.setup_dap { hotcodereplace = 'auto' }
  jdtls.setup.add_commands()
  local map = vim.keymap.set
  local opts = { buffer = bufnr, noremap = true, silent = true }
  map('n', '<leader>oi', jdtls.organize_imports, opts)
  map('n', '<leader>ev', jdtls.extract_variable, opts)
  map('v', '<leader>em', jdtls.extract_method, opts)
end
return M
