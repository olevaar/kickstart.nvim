local dap = require 'dap'

local function current_file_fqn()
  local buf = 0
  local path = vim.api.nvim_buf_get_name(buf)
  if not path or path == '' then
    return nil
  end

  local cls = path:match '([^/]+)%.java$'
  if not cls then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, math.min(200, vim.api.nvim_buf_line_count(buf)), false)
  for _, l in ipairs(lines) do
    local pkg = l:match '^%s*package%s+([%w_%.]+)%s*;'
    if pkg and pkg ~= '' then
      return pkg .. '.' .. cls
    end
  end

  local rel = path:match '/src/[%w%-]+/java/(.+)%.java$'
  if rel then
    return (rel:gsub('/', '.'))
  end

  return cls
end

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

local function find_java_home(version)
  local env_var = 'JAVA_HOME_' .. version
  local from_env = os.getenv(env_var)
  if from_env and vim.fn.isdirectory(from_env) == 1 then
    return from_env
  end

  local handle = io.popen 'java -version 2>&1'
  if handle then
    local result = handle:read '*a'
    handle:close()
    if result and result:match('version "' .. version) then
      handle = io.popen 'which java 2>/dev/null'
      if handle then
        local java_path = handle:read '*a'
        handle:close()
        if java_path and java_path ~= '' then
          handle = io.popen('readlink -f ' .. vim.fn.shellescape(java_path:gsub('\n', '')) .. ' 2>/dev/null')
          if handle then
            local real_path = handle:read '*a'
            handle:close()
            if real_path and real_path ~= '' then
              local java_home = real_path:gsub('\n', ''):match '(.+)/bin/java$'
              if java_home and vim.fn.isdirectory(java_home) == 1 then
                return java_home
              end
            end
          end
        end
      end
    end
  end

  return '/usr/lib/jvm/java-' .. version .. '-openjdk-amd64'
end

local java11 = find_java_home '11'
-- local java17 = os.getenv 'JAVA_HOME_17' or '/usr/lib/jvm/java-17-openjdk-amd64'
-- local java21 = os.getenv 'JAVA_HOME_21' or '/usr/lib/jvm/java-21-openjdk-amd64'

dap.configurations.java = dap.configurations.java or {}

table.insert(dap.configurations.java, {
  type = 'java',
  request = 'launch',
  name = 'Debug (Launch) java msp',
  __manual = true,
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
    return current_file_fqn()
  end,
  cwd = '${workspaceFolder}',
  console = 'internalConsole',
  stopOnEntry = true,
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
  if not dap.adapters.java then
    vim.notify('Java DAP not initialized yet. Open a Java file so JDTLS can set it up.', vim.log.levels.WARN)
    return
  end

  local configs = dap.configurations.java or {}

  for _, c in ipairs(configs) do
    if c.name == 'Debug (Launch) Current File' then
      local mc = type(c.mainClass) == 'function' and c.mainClass() or c.mainClass
      if not mc or mc == '' or not mc:find '%.' then
        local ok, jdtls = pcall(require, 'jdtls')
        if ok and jdtls.pick_main_class then
          jdtls.pick_main_class()
          return
        end
        vim.notify('Could not resolve fully-qualified main class for current file.', vim.log.levels.ERROR)
        return
      end
      c.mainClass = mc
      dap.run(c)
      return
    end
  end

  local ok, jdtls = pcall(require, 'jdtls')
  if ok and jdtls.pick_main_class then
    jdtls.pick_main_class()
    return
  end
  vim.notify('No suitable Java launch config found.', vim.log.levels.ERROR)
end, {})
