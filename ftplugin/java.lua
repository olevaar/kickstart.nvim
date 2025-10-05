-- ~/.config/nvim/ftplugin/java.lua
-- Minimal jdtls for Maven projects + debugging

local jdtls = require 'jdtls'
local jdtls_config = require 'configs.jdtls' -- Importing the refactored configuration

local config = jdtls_config.config

config.on_attach = function(client, bufnr)
  require 'configs.java_run'
  jdtls.setup_dap { hotcodereplace = 'auto' }
  require('jdtls.dap').setup_dap_main_class_configs()
end

jdtls.start_or_attach(config)
