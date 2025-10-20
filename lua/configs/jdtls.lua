local M = {}

local mason = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'

local function find_launcher()
  local matches = vim.fn.glob(mason .. '/plugins/org.eclipse.equinox.launcher_*.jar', true, true)
  if type(matches) == 'table' and #matches > 0 then
    return matches[1]
  end
  return mason .. '/plugins/org.eclipse.equinox.launcher.jar'
end

local function jdtls_config_dir()
  local sys = (vim.loop.os_uname().sysname or ''):lower()
  if sys:find 'darwin' then
    return mason .. '/config_mac'
  end
  if sys:find 'windows' or sys:find 'mingw' then
    return mason .. '/config_win'
  end
  return mason .. '/config_linux'
end

local function workspace_dir(root)
  local base = vim.fn.stdpath 'data' .. '/jdtls_workspaces'
  return base .. '/' .. vim.fs.basename(root)
end

function M.build(root, opts)
  opts = opts or {}
  local LOMBOK_JAR = mason .. '/lombok.jar'
  local JDTLS_JAR = find_launcher()
  local JDTLS_CFG = jdtls_config_dir()

  local cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. LOMBOK_JAR,
    '-jar',
    JDTLS_JAR,
    '-configuration',
    JDTLS_CFG,
    '-data',
    workspace_dir(root),
  }

  local settings = vim.tbl_deep_extend('force', {
    java = {
      configuration = { updateBuildConfiguration = 'interactive' },
      maven = { downloadSources = true },
      format = { enabled = true },
      autobuild = { enabled = true },
    },
  }, opts.settings or {})

  return {
    cmd = cmd,
    root_dir = root,
    settings = settings,
    init_options = { bundles = opts.extra_bundles or {} },
    on_attach = opts.on_attach,
  }
end

return M
