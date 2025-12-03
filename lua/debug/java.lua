local ok_jdtls, jdtls = pcall(require, 'jdtls')
local ok_dap, dap = pcall(require, 'dap')
if not ok_jdtls or not ok_dap then
  return
end

local function ensure_jdtls_dap()
  local bufnr = vim.api.nvim_get_current_buf()
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  local attached = false
  for _, client in pairs(get_clients { bufnr = bufnr }) do
    if client.name == 'jdtls' then
      attached = true
      break
    end
  end
  if not attached then
    pcall(function()
      require('lsp.jdtls').start()
    end)
    for _, client in pairs(get_clients { bufnr = bufnr }) do
      if client.name == 'jdtls' then
        attached = true
        break
      end
    end
  end
  if not attached then
    return false
  end
  pcall(function()
    jdtls.setup_dap { hotcodereplace = 'auto' }
    jdtls.setup_dap_main_class_configs()
  end)
  return true
end

local function resolve_main_class(bufnr)
  bufnr = bufnr or 0
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' then
    return nil
  end
  local roots = {
    '/src/main/java/',
    '/src/test/java/',
    '/src/',
  }
  local class_path
  for _, root in ipairs(roots) do
    local idx = filepath:find(root, 1, true)
    if idx then
      class_path = filepath:sub(idx + #root)
      break
    end
  end
  class_path = class_path or filepath:match '([^/]+%.java)$'
  if not class_path then
    return nil
  end
  return class_path:gsub('%.java$', ''):gsub('/', '.'):gsub('\\', '.')
end

local function java_default_configs()
  local cwd = vim.fn.getcwd()
  local configs = {
    {
      type = 'java',
      request = 'launch',
      name = 'Launch MainClass',
      mainClass = '',
      args = '',
      vmArgs = '',
      cwd = cwd,
      console = 'integratedTerminal',
    },
  }
  local current_main = resolve_main_class(0)
  if current_main and #current_main > 0 then
    table.insert(configs, {
      type = 'java',
      request = 'launch',
      name = 'Launch Current Buffer',
      mainClass = current_main,
      args = '',
      vmArgs = '',
      cwd = cwd,
      console = 'integratedTerminal',
    })
  end
  return configs
end

local function find_jdk(version)
  local candidates = vim.fn.glob('/usr/lib/jvm/*', true, true)
  for _, path in ipairs(candidates) do
    if path:match(tostring(version)) then
      local binjava = path .. '/bin/java'
      if vim.fn.filereadable(binjava) == 1 then
        return path
      end
    end
  end
  return nil
end

vim.api.nvim_create_user_command('JavaLaunchMain', function(opts)
  local cwd = vim.fn.getcwd()
  if not ensure_jdtls_dap() then
    return
  end
  local projectName = vim.fn.fnamemodify(cwd, ':t')
  local config = {
    type = 'java',
    request = 'launch',
    name = 'Launch MainClass',
    mainClass = opts.args ~= '' and opts.args or '',
    projectName = projectName,
    args = '',
    vmArgs = '',
    cwd = cwd,
    console = 'integratedTerminal',
  }
  dap.run(config)
end, {
  nargs = '?',
  complete = function()
    return {}
  end,
  desc = 'DAP: Launch Java mainClass (pass FQN as argument)',
})

vim.api.nvim_create_user_command('JavaLaunchMainWithJDK', function(opts)
  local args = vim.split(opts.args or '', '%s+')
  local version = tonumber(args[1])
  local mainClass = args[2] or ''
  if not version or (version ~= 11 and version ~= 17 and version ~= 21) then
    vim.notify('Usage: :JavaLaunchMainWithJDK {11|17|21} <MainClass>', vim.log.levels.ERROR)
    return
  end
  if not ensure_jdtls_dap() then
    return
  end
  local cwd = vim.fn.getcwd()
  local projectName = vim.fn.fnamemodify(cwd, ':t')
  local jdk = find_jdk(version)
  if not jdk then
    vim.notify('JDK ' .. version .. ' not found under /usr/lib/jvm', vim.log.levels.ERROR)
    return
  end
  local env = vim.tbl_extend('force', vim.fn.environ(), {
    JAVA_HOME = jdk,
    PATH = jdk .. '/bin:' .. vim.fn.environ().PATH,
  })
  local config = {
    type = 'java',
    request = 'launch',
    name = 'Launch MainClass (JDK ' .. version .. ')',
    mainClass = mainClass,
    projectName = projectName,
    args = '',
    vmArgs = '',
    cwd = cwd,
    console = 'integratedTerminal',
    env = env,
  }
  dap.run(config)
end, { nargs = '+', desc = 'Launch Java mainClass with selected JDK version' })

vim.api.nvim_create_user_command('JavaLaunchCurrent', function()
  local cwd = vim.fn.getcwd()
  local current_main = resolve_main_class(0)
  if not current_main or #current_main == 0 then
    return
  end
  if not ensure_jdtls_dap() then
    return
  end
  local configs = type(dap.configurations.java) == 'table' and dap.configurations.java or java_default_configs()
  local selected
  for _, cfg in ipairs(configs) do
    if cfg.type == 'java' and cfg.request == 'launch' and (cfg.mainClass == current_main or (cfg.name and cfg.name:find(current_main, 1, true))) then
      selected = cfg
      break
    end
  end
  if not selected then
    selected = {
      type = 'java',
      request = 'launch',
      name = 'Launch Current Buffer',
      mainClass = current_main,
      args = '',
      vmArgs = '',
      cwd = cwd,
      console = 'integratedTerminal',
    }
  end
  if not selected.projectName or selected.projectName == '' then
    selected.projectName = vim.fn.fnamemodify(cwd, ':t')
  end
  dap.run(selected)
end, { desc = 'DAP: Launch Java using current buffer as mainClass' })

vim.api.nvim_create_user_command('JavaDebugHealth', function()
  local lines = {}
  local function add(msg)
    table.insert(lines, msg)
  end

  local mason_path = vim.fn.stdpath 'data' .. '/mason'
  local debug_bundle = vim.fn.glob(mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')
  add('Debug bundle: ' .. (debug_bundle ~= '' and debug_bundle or '<missing>'))
  local test_bundles = vim.split(vim.fn.glob(mason_path .. '/packages/java-test/extension/server/*.jar'), '\n')
  local test_count = 0
  for _, b in ipairs(test_bundles) do
    if b ~= '' then
      test_count = test_count + 1
      add('Test bundle: ' .. b)
    end
  end
  if test_count == 0 then
    add 'Test bundles: <none>'
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  local jdtls_client
  for _, client in pairs(get_clients { bufnr = bufnr }) do
    if client.name == 'jdtls' then
      jdtls_client = client
      break
    end
  end
  add('JDTLS attached: ' .. (jdtls_client and 'yes' or 'no'))
  if jdtls_client then
    local caps = jdtls_client.server_capabilities or {}
    local cap_list = {}
    for k, v in pairs(caps) do
      table.insert(cap_list, tostring(k) .. '=' .. (type(v) == 'boolean' and tostring(v) or '[obj]'))
    end
    table.sort(cap_list)
    add('JDTLS capabilities: ' .. table.concat(cap_list, ', '))
  end

  local configs = type(dap.configurations.java) == 'function' and dap.configurations.java() or (dap.configurations.java or {})
  add('DAP java configs count: ' .. tostring(#configs))
  for i, cfg in ipairs(configs) do
    add(('  [%d] %s type=%s request=%s mainClass=%s'):format(i, cfg.name or '<noname>', cfg.type or '', cfg.request or '', cfg.mainClass or ''))
  end

  local java_home = os.getenv 'JAVA_HOME'
  add('JAVA_HOME: ' .. (java_home or '<not set>'))
  local java_version = vim.fn.systemlist 'java -version'
  if vim.v.shell_error ~= 0 then
    add 'java -version: <error> (is Java in PATH?)'
  else
    for _, l in ipairs(java_version) do
      add('java -version: ' .. l)
    end
  end

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Java Debug Health' })
end, { desc = 'Show Java debug health information' })

vim.api.nvim_create_user_command('JavaLaunchDetected', function()
  if not ensure_jdtls_dap() then
    return
  end
  local configs = type(dap.configurations.java) == 'function' and dap.configurations.java() or (dap.configurations.java or {})
  if #configs == 0 then
    vim.notify('No Java DAP configurations detected', vim.log.levels.WARN)
    return
  end
  local cfg = configs[1]
  dap.run(cfg)
end, { desc = 'Launch first jdtls-detected Java main configuration' })
