local M = {}

function M.config()
  local jdtls_ok, jdtls = pcall(require, 'jdtls')
  if not jdtls_ok then
    return nil
  end

  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspaces/' .. project_name

  local mason_path = vim.fn.stdpath 'data' .. '/mason'
  local jdtls_root = mason_path .. '/packages/jdtls'

  local os_config = (function()
    if vim.fn.has 'mac' == 1 then
      return 'config_mac'
    elseif vim.fn.has 'win32' == 1 then
      return 'config_win'
    else
      return 'config_linux'
    end
  end)()

  local cmd = {
    jdtls_root .. '/bin/jdtls',
    '-data',
    workspace_dir,
    '--jvm-args',
    '-Xms512m',
  }

  local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
  local root_dir = require('jdtls.setup').find_root(root_markers)
  if root_dir == nil then
    root_dir = vim.fn.getcwd()
  end

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- Include debug/test bundles so jdtls exposes startDebugSession capability
  local bundles = {}
  local debug_bundle = vim.fn.glob(mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')
  if debug_bundle ~= '' then
    table.insert(bundles, debug_bundle)
  end
  local test_bundles = vim.split(vim.fn.glob(mason_path .. '/packages/java-test/extension/server/*.jar'), '\n')
  for _, b in ipairs(test_bundles) do
    if b ~= '' then
      table.insert(bundles, b)
    end
  end

  return {
    cmd = cmd,
    root_dir = root_dir,
    capabilities = capabilities,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = 'fernflower' },
      },
    },
    init_options = {
      workspace = workspace_dir,
      bundles = bundles,
    },
  }
end

return M
