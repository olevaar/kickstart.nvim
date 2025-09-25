local jdtls = require 'jdtls'
local cfg = require 'configs.jdtls'
local root_markers = { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if root_dir == '' then
  root_dir = vim.fn.getcwd()
end
local config = {
  cmd = cfg.cmd(),
  root_dir = root_dir,
  settings = cfg.settings,
  init_options = { bundles = {} },
}
config.on_attach = cfg.on_attach
jdtls.start_or_attach(config)
