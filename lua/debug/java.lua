local dap = require 'dap'

local function load_env_file(path)
  local env = {}
  local f = io.open(path, 'r')
  if not f then
    return env
  end
  for line in f:lines() do
    line = line:gsub('^%s+', ''):gsub('%s+$', '')
    if line ~= '' and not line:match '^#' then
      line = line:gsub('^export%s+', '')
      local k, v = line:match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$'
      if k and v then
        v = v:gsub('^[\'"](.*)[\'"]$', '%1')
        env[k] = v
      end
    end
  end
  f:close()
  return env
end

local java11 = os.getenv 'JAVA_HOME_11' or '/usr/lib/jvm/java-11-openjdk-amd64'
local java17 = os.getenv 'JAVA_HOME_17' or '/usr/lib/jvm/java-17-openjdk-amd64'
local java21 = os.getenv 'JAVA_HOME_21' or '/usr/lib/jvm/java-21-openjdk-amd64'

dap.configurations.java = dap.configurations.java or {}

table.insert(dap.configurations.java, {
  type = 'java',
  request = 'launch',
  name = 'Debug (Launch) java msp',
  mainClass = 'com.lgc.dist.core.msp.grizzly.GrizzlyServer',
  cwd = '${workspaceFolder}',
  env = function()
    local root = vim.fn.getcwd()
    return load_env_file(root .. '/oec_env.list')
  end,
  console = 'integratedTerminal',
  javaExec = java11 .. '/bin/java',
})

table.insert(dap.configurations.java, {
  type = 'java',
  request = 'launch',
  name = 'Debug (Launch) Current File',
  mainClass = function()
    local current_file = vim.api.nvim_buf_get_name(0)
    return current_file:gsub('.*/', ''):gsub('%.java$', '')
  end,
  cwd = '${workspaceFolder}',
  console = 'integratedTerminal',
})

vim.api.nvim_create_user_command('JavaMspRun', function()
  for _, c in ipairs(dap.configurations.java) do
    if c.name == 'Debug (Launch) java msp' then
      dap.run(c)
      return
    end
  end
  vim.notify('Java DAP config not found', vim.log.levels.ERROR)
end, {})

vim.api.nvim_create_user_command('JavaRun', function()
  local dap = require 'dap'
  if not dap.adapters.java then
    vim.notify('Java DAP not initialized yet. Open a Java file so JDTLS can set it up.', vim.log.levels.WARN)
    return
  end
  for _, c in ipairs(dap.configurations.java or {}) do
    if c.request == 'launch' and c.mainClass then
      dap.run(c)
      return
    end
  end
  vim.notify('No Java launch configs found. Try reopening the project, or run: :lua require("jdtls.dap").setup_dap_main_class_configs()', vim.log.levels.ERROR)
end, {})
