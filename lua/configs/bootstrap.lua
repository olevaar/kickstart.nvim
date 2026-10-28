-- Headless checks used by install.sh. Each function raises an error on
-- failure; install.sh turns that into a non-zero exit code.
local M = {}

function M.verify_plugins()
  local missing = {}
  for name, plugin in pairs(require('lazy.core.config').plugins) do
    if not plugin._.is_local and not plugin._.installed then
      table.insert(missing, name)
    end
  end
  if #missing > 0 then
    table.sort(missing)
    error('plugins not installed: ' .. table.concat(missing, ', '))
  end
end

function M.install_mason_sync()
  vim.cmd 'MasonToolsInstallSync'
  local registry = require 'mason-registry'
  local to_package = require('mason-lspconfig').get_mappings().lspconfig_to_package
  local missing = {}
  for _, name in ipairs(require 'configs.mason_packages') do
    local package = to_package[name] or name
    if not registry.is_installed(package) then
      table.insert(missing, package)
    end
  end
  if #missing > 0 then
    error('Mason packages not installed: ' .. table.concat(missing, ', '))
  end
end

return M
