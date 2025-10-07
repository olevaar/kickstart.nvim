local dap = require 'dap'

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
  envFile = '${workspaceFolder}/oec_env.list',
  console = 'intetralTerminal',
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
      require('dap').run(c)
      return
    end
  end
  vim.notify('Java DAP config not found', vim.log.levels.ERROR)
end, {})

vim.api.nvim_create_user_command('JavaRun', function()
  for _, c in ipairs(dap.configurations.java) do
    if c.name == 'Debug (Launch) Current File' then
      require('dap').run(c)
      return
    end
  end
  vim.notify('Generic Java DAP config not found', vim.log.levels.ERROR)
end, {})
