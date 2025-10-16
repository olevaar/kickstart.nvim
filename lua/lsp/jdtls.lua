local M = {}

local started = {} ---@type table<string, boolean>

local function find_root_from(dir)
  local markers = { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
  local found = vim.fs.find(markers, { upward = true, path = dir })[1]
  return found and vim.fs.dirname(found) or nil
end

local function has_any(root, pattern, limit)
  local hits = vim.fs.find(function(name)
    return name:match(pattern)
  end, { path = root, limit = limit or 20 })
  return #hits > 0
end

local function project_has_java(root)
  if vim.uv.fs_stat(root .. '/src/main/java') or vim.uv.fs_stat(root .. '/src/test/java') then
    return true
  end
  return has_any(root, '%.java$', 20)
end

local function project_has_kotlin(root)
  if vim.uv.fs_stat(root .. '/src/main/kotlin') or vim.uv.fs_stat(root .. '/src/test/kotlin') then
    return true
  end
  return has_any(root, '%.kt$', 20)
end

local function file_contains(path, needles)
  local f = io.open(path, 'r')
  if not f then
    return false
  end
  local ok, content = pcall(function()
    return f:read '*a'
  end)
  f:close()
  if not ok or not content then
    return false
  end
  content = content:lower()
  for _, n in ipairs(needles) do
    if content:find(n, 1, true) then
      return true
    end
  end
  return false
end

local function buildfiles_indicate_kotlin(root)
  for _, p in ipairs { root .. '/build.gradle', root .. '/build.gradle.kts' } do
    if file_contains(p, { 'kotlin(', 'org.jetbrains.kotlin', 'kotlin-android', 'kotlin-dsl' }) then
      return true
    end
  end
  if file_contains(root .. '/pom.xml', { '<groupid>org.jetbrains.kotlin</groupid>', 'kotlin-maven-plugin' }) then
    return true
  end
  return false
end

local function is_kotlin_only(root)
  local has_java = project_has_java(root)
  local has_kotlin = project_has_kotlin(root) or buildfiles_indicate_kotlin(root)
  return (not has_java) and has_kotlin
end

local function collect_bundles()
  local mr = vim.fn.stdpath 'data' .. '/mason/packages'
  local dbg = mr .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
  local tst = mr .. '/java-test/extension/server/*.jar'
  local bundles = {}
  local function push(globpat)
    local m = vim.fn.glob(globpat, true, true)
    if type(m) == 'table' then
      for _, x in ipairs(m) do
        table.insert(bundles, x)
      end
    end
  end
  push(dbg)
  push(tst)
  return bundles
end

local function start_for_root(root, opts)
  opts = opts or {}
  if opts.skip_kotlin_only ~= false and is_kotlin_only(root) then
    return
  end

  local ok_jdtls, jdtls = pcall(require, 'jdtls')
  if not ok_jdtls then
    vim.notify('nvim-jdtls not found (install mfussenegger/nvim-jdtls)', vim.log.levels.ERROR)
    return
  end

  local ok_cfg, build = pcall(require, 'configs.jdtls')
  if not ok_cfg then
    vim.notify("configs/jdtls.lua not found (require('configs.jdtls'))", vim.log.levels.ERROR)
    return
  end

  local cfg = build.build(root, opts.config_opts or {})
  local bundles = collect_bundles()
  cfg.init_options = cfg.init_options or {}
  cfg.init_options.bundles = cfg.init_options.bundles or {}
  vim.list_extend(cfg.init_options.bundles, bundles)

  jdtls.start_or_attach(cfg)
  started[root] = true

  jdtls.setup_dap { hotcodereplace = 'auto' }

  local function jdtls_attached_for_root()
    for _, c in ipairs(vim.lsp.get_clients { name = 'jdtls' }) do -- get_active_clients() is deprecated
      if c.config and c.config.root_dir == root then
        return true
      end
    end
    return false
  end

  local function gen_main_class_configs()
    pcall(function()
      require('jdtls.dap').setup_dap_main_class_configs()
    end)
  end

  if jdtls_attached_for_root() then
    gen_main_class_configs()
  else
    vim.defer_fn(function()
      if jdtls_attached_for_root() then
        gen_main_class_configs()
      end
    end, 250)
  end
end

function M.start_from_cwd(opts)
  local cwd = vim.loop.cwd()
  if not cwd or cwd == '' then
    return
  end
  local root = find_root_from(cwd)
  if not root then
    return
  end
  start_for_root(root, opts)
end

function M.start_for_dir(dir, opts)
  local root = find_root_from(dir)
  if not root then
    return
  end
  start_for_root(root, opts)
end

function M.start_for_current_buffer(opts)
  local bufname = vim.api.nvim_buf_get_name(0)
  local dir
  if bufname == '' then
    dir = vim.loop.cwd()
  else
    local stat = vim.uv.fs_stat(bufname)
    dir = (stat and stat.type == 'directory') and bufname or vim.fs.dirname(bufname)
  end
  if not dir then
    return
  end
  local root = find_root_from(dir)
  if not root then
    return
  end
  start_for_root(root, opts)
end

return M
