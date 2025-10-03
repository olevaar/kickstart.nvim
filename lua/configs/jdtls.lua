-- Configuration details for jdtls

local M = {}

-- Detect project root
local root_markers = { 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers) or vim.loop.cwd()
local project_name = vim.fn.fnamemodify(root_dir, ':t')

-- JDK to run jdtls (adjust if needed)
local java_home = os.getenv 'JAVA_HOME' or '/usr/lib/jvm/java-21-openjdk-amd64'
local java_bin = java_home .. '/bin/java'

-- Mason jdtls layout
local mason = vim.fn.stdpath 'data' .. '/mason'
local jdtls_base = mason .. '/packages/jdtls'
local lombok_jar = jdtls_base .. '/lombok.jar'
local launcher_jar = vim.fn.glob(jdtls_base .. '/plugins/org.eclipse.equinox.launcher_*.jar')
local config_dir = jdtls_base .. '/config_linux' -- use _mac or _win if relevant
local workspace = vim.fn.stdpath 'state' .. '/jdtls-workspaces/' .. project_name

-- Debug bundle (only this one; keep it minimal)
local debug_bundle = vim.fn.globpath(mason .. '/share/java-debug-adapter', 'com.microsoft.java.debug.plugin-*.jar', true, true)

M.config = {
  cmd = {
    java_bin,
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=false',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    launcher_jar,
    '-configuration',
    config_dir,
    '-data',
    workspace,
  },
  root_dir = root_dir,
  settings = {
    java = {
      import = {
        maven = {
          enabled = true,
          userSettings = root_dir .. '.mvn/settings.xml',
        },
      },
      project = {
        referencedLibraries = {
          root_dir .. '/.m2-local/**/*.jar',
        },
      },
      signatureHelp = { enabled = true },
    },
  },
  init_options = { bundles = debug_bundle },
}

return M

