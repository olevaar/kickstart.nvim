local M = {}

function M.start()
  local ok, jdtls = pcall(require, 'jdtls')
  if not ok then
    return
  end
  local cfg = require('configs.jdtls').config()
  if not cfg then
    return
  end
  jdtls.start_or_attach(cfg)
end

return M
