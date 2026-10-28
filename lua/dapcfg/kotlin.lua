-- Debugging through JetBrains' Kotlin LSP. The server has its own debug
-- adapter: `start_debug_server` opens a DAP port, and the launch is resolved
-- through the same LSP commands the official VS Code extension uses.
local M = {}

local JVM = 'intellij_jvm'
local GRADLE = 'intellij_gradle'

local function notify(msg, level)
  vim.notify('Kotlin debug: ' .. msg, level or vim.log.levels.INFO)
end

local function kotlin_client(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.lsp.get_clients({ name = 'kotlin_lsp', bufnr = bufnr })[1] or vim.lsp.get_clients({ name = 'kotlin_lsp' })[1]
end

-- Runs a server command from inside a coroutine and returns its result.
local function exec(client, command, arguments)
  local co = coroutine.running()
  local sent = client:request('workspace/executeCommand', { command = command, arguments = arguments }, function(err, result)
    coroutine.resume(co, err, result)
  end)
  if not sent then
    error(command .. ': the language server is not running', 0)
  end
  local err, result = coroutine.yield()
  if err then
    error(command .. ': ' .. (err.message or vim.inspect(err)), 0)
  end
  return result
end

local function system(cmd, cwd)
  local co = coroutine.running()
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      coroutine.resume(co, res)
    end)
  end)
  return coroutine.yield()
end

-- Compiles the module before a JVM launch, as the VS Code extension does.
-- Gradle launches build as part of running, so they skip this.
local function build(client, uri)
  local cmd = exec(client, 'intellij.java.resolveBuildCommand', { { uri = uri } })
  if not (cmd and cmd.supported and cmd.command and #cmd.command > 0) then
    return
  end
  notify('building: ' .. table.concat(cmd.command, ' '))
  local res = system(cmd.command, cmd.cwd)
  if res.code ~= 0 then
    local out = vim.split(vim.trim((res.stdout or '') .. '\n' .. (res.stderr or '')), '\n')
    error('build failed:\n' .. table.concat(vim.list_slice(out, math.max(1, #out - 20)), '\n'), 0)
  end
end

local function target_uri(client, config)
  if config.file and config.file ~= '' then
    return vim.uri_from_fname(config.file)
  end
  return exec(client, 'intellij.java.resolveClassDocument', { { fqn = config.mainClass } }).uri
end

local function resolve_jvm(client, config, uri)
  if config.build ~= false then
    build(client, uri)
  end
  -- Must serialise as a JSON object even when every field is nil.
  local overrides = vim.empty_dict()
  for _, key in ipairs { 'classPaths', 'modulePaths', 'moduleName', 'javaExec', 'vmArgs' } do
    overrides[key] = config[key]
  end
  local paths = exec(client, 'intellij.java.resolveLaunch', {
    {
      uri = uri,
      cwd = config.cwd,
      overrides = overrides,
    },
  })
  config.tool = 'java'
  config.classPaths = paths.classpath or {}
  config.modulePaths = paths.modulePath or {}
  config.moduleName = paths.moduleName or config.moduleName
  config.moduleContentPaths = paths.moduleContentPaths or {}
  config.cwd = paths.workingDirectory or config.cwd
  config.javaExec = paths.javaExec
  config.vmArgs = paths.vmArgs or config.vmArgs
end

local function resolve_gradle(client, config, uri)
  local launch = exec(client, 'intellij.java.resolveBuildToolLaunch', { { uri = uri, mainClass = config.mainClass } })
  if not launch.tool then
    error(('no build tool can launch %s; use an "%s" configuration'):format(config.mainClass, JVM), 0)
  end
  config.tool = launch.tool
  config.toolArgs = config.gradleArgs
  config.buildToolTarget = {
    uri = uri,
    moduleName = launch.moduleName,
    projectPath = config.projectPath,
    sourceSet = config.sourceSet,
    toolArgs = config.gradleArgs,
  }
  config.classPaths = launch.scopeClassPaths or {}
end

local function enrich(config, on_config)
  if config.request ~= 'launch' then
    return on_config(config)
  end
  coroutine.wrap(function()
    local ok, err = pcall(function()
      local client = assert(kotlin_client(), 'the Kotlin language server is not running')
      config = vim.deepcopy(config)
      assert(config.mainClass and config.mainClass ~= '', 'the configuration needs "mainClass"')
      local uri = target_uri(client, config)
      if config.type == GRADLE then
        resolve_gradle(client, config, uri)
      else
        resolve_jvm(client, config, uri)
      end
      config.console = config.console or 'internalConsole'
    end)
    if ok then
      on_config(config)
    else
      notify(tostring(err), vim.log.levels.ERROR)
    end
  end)()
end

local function adapter(callback, config)
  local client = kotlin_client()
  if not client then
    return notify('the Kotlin language server is not running', vim.log.levels.ERROR)
  end
  coroutine.wrap(function()
    local ok, port = pcall(exec, client, 'start_debug_server', { vim.uri_from_fname(client.root_dir) })
    if not ok or type(port) ~= 'number' then
      return notify('could not start the debug server: ' .. tostring(port), vim.log.levels.ERROR)
    end
    -- The server rejects nvim-dap's default adapterID.
    callback { type = 'server', host = '127.0.0.1', port = port, id = config.type, enrich_config = enrich }
  end)()
end

-- Main classes in a buffer, from the server's Run/Debug code lenses.
local function main_classes(bufnr)
  local client = kotlin_client(bufnr)
  if not client then
    return {}
  end
  local res = client:request_sync('textDocument/codeLens', { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }, 10000, bufnr)
  local seen, classes = {}, {}
  for _, lens in ipairs(res and res.result or {}) do
    local arg = lens.command and lens.command.command == 'intellij.jvm.runMain' and (lens.command.arguments or {})[1]
    if arg and not seen[arg.mainClass] then
      seen[arg.mainClass] = true
      table.insert(classes, arg.mainClass)
    end
  end
  return classes
end

local function pick_main_class()
  local classes = main_classes(vim.api.nvim_get_current_buf())
  if #classes == 1 then
    return classes[1]
  end
  if #classes > 1 then
    return require('dap.ui').pick_one(classes, 'Main class: ', tostring)
  end
  local input = vim.fn.input 'Main class (e.g. com.example.MainKt): '
  return input ~= '' and input or require('dap').ABORT
end

function M.setup_dap(dap)
  dap.adapters[JVM] = adapter
  dap.adapters[GRADLE] = adapter
  dap.configurations.kotlin = {
    {
      type = JVM,
      request = 'launch',
      name = 'Kotlin: launch main class',
      mainClass = pick_main_class,
      file = '${file}',
    },
    {
      type = GRADLE,
      request = 'launch',
      name = 'Kotlin: launch main class with Gradle',
      mainClass = pick_main_class,
      file = '${file}',
    },
    {
      type = JVM,
      request = 'attach',
      name = 'Kotlin: attach to JVM on port 5005',
      hostName = '127.0.0.1',
      port = 5005,
    },
  }
end

-- Handles the server's Run/Debug code lens (`grx`, or `vim.lsp.codelens.run()`).
local function run_main(command)
  local arg = (command.arguments or {})[1]
  if not arg or not arg.mainClass then
    return notify('the code lens has no main class', vim.log.levels.ERROR)
  end
  local client = kotlin_client()
  coroutine.wrap(function()
    local tool
    if client then
      local ok, launch = pcall(exec, client, 'intellij.java.resolveBuildToolLaunch', { { uri = arg.uri, mainClass = arg.mainClass } })
      tool = ok and launch.tool or nil
    end
    require('dap').run {
      type = tool == 'gradle' and GRADLE or JVM,
      request = 'launch',
      name = arg.mainClass:match '[^.]+$',
      mainClass = arg.mainClass,
      file = arg.uri and vim.uri_to_fname(arg.uri) or nil,
      noDebug = arg.noDebug,
    }
  end)()
end

--- Options merged into the kotlin_lsp client config.
function M.lsp_config()
  return {
    init_options = { runMainCodeLens = true },
    commands = { ['intellij.jvm.runMain'] = run_main },
    on_attach = function(client, bufnr)
      vim.lsp.codelens.enable(true, { bufnr = bufnr, client_id = client.id })
    end,
  }
end

return M
