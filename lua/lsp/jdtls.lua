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
  local gradle_files = { root .. '/build.gradle', root .. '/build.gradle.kts' }
  for _, p in ipairs(gradle_files) do
    if file_contains(p, {
      'kotlin(',
      'org.jetbrains.kotlin',
      'kotlin-android',
      'kotlin-dsl',
    }) then
      return true
    end
  end
  local pom = root .. '/pom.xml'
  if file_contains(pom, {
    '<groupid>org.jetbrains.kotlin</groupid>',
    'kotlin-maven-plugin',
  }) then
    return true
  end
  return false
end

local function is_kotlin_only(root)
  local has_java = project_has_java(root)
  local has_kotlin = project_has_kotlin(root) or buildfiles_indicate_kotlin(root)
  return (not has_java) and has_kotlin
end

local function start_for_root(root, opts)
  opts = opts or {}
  if started[root] then
    return
  end
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
  jdtls.start_or_attach(cfg)
  started[root] = true
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
    if stat and stat.type == 'directory' then
      dir = bufname
    else
      dir = vim.fs.dirname(bufname)
    end
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
