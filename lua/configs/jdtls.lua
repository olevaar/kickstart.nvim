local M = {}

local root_markers = { 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts', '.git' }

local function config_dir(jdtls_root)
  local arch = vim.uv.os_uname().machine
  local arm = arch == 'arm64' or arch == 'aarch64'
  local os_name = vim.fn.has 'mac' == 1 and 'mac' or vim.fn.has 'win32' == 1 and 'win' or 'linux'
  local dir = jdtls_root .. '/config_' .. os_name .. (arm and '_arm' or '')
  if arm and vim.fn.isdirectory(dir) == 0 then
    dir = jdtls_root .. '/config_' .. os_name
  end
  return dir
end

function M.config()
  local jdtls_ok = pcall(require, 'jdtls')
  if not jdtls_ok then
    return nil
  end

  local root_dir = vim.fs.root(0, root_markers) or vim.fn.getcwd()
  -- Hash the full path so projects sharing a directory name get separate workspaces.
  local project_name = vim.fn.fnamemodify(root_dir, ':t') .. '-' .. vim.fn.sha256(root_dir):sub(1, 8)
  local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspaces/' .. project_name

  local mason_path = vim.fn.stdpath 'data' .. '/mason'
  local jdtls_root = mason_path .. '/packages/jdtls'

  local launcher_jar = vim.fn.glob(jdtls_root .. '/plugins/org.eclipse.equinox.launcher_*.jar', true, true)[1]
    or (jdtls_root .. '/plugins/org.eclipse.equinox.launcher.jar')

  local cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Xmx2g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
  }
  if vim.env.JDTLS_DEBUG then
    vim.list_extend(cmd, { '-Dlog.protocol=true', '-Dlog.level=ALL' })
  end
  -- Java refuses to start if a -javaagent jar is missing.
  local lombok_jar = jdtls_root .. '/lombok.jar'
  if vim.fn.filereadable(lombok_jar) == 1 then
    table.insert(cmd, '-javaagent:' .. lombok_jar)
  end
  vim.list_extend(cmd, {
    '-jar',
    launcher_jar,
    '-configuration',
    config_dir(jdtls_root),
    '-data',
    workspace_dir,
  })

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  local bundles = vim.fn.glob(mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true, true)
  vim.list_extend(bundles, vim.fn.glob(mason_path .. '/packages/java-test/extension/server/*.jar', true, true))

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
