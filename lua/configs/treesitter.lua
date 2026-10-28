local M = {}

M.parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'java',
  'javascript',
  'typescript',
  'css',
  'kotlin',
  'sql',
  'go',
}

-- Install parsers for other filetypes on first use.
local auto_install = true

-- Languages that keep regex syntax highlighting alongside treesitter.
local regex_highlight = { ruby = true }

-- Languages that use Vim's indent scripts instead of treesitter indentation.
local indent_disabled = { ruby = true }

local function has_cli()
  return vim.fn.executable 'tree-sitter' == 1
end

local warned = false
local function warn_missing_cli()
  if warned then
    return
  end
  warned = true
  vim.notify('nvim-treesitter: tree-sitter CLI not found; parsers cannot be installed. Run install.sh or install tree-sitter >= 0.26.1.', vim.log.levels.WARN)
end

local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return true
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local active = vim.treesitter.highlighter.active[buf]
  if active and active.tree:lang() == lang then
    return true
  end
  if not lang or not vim.treesitter.language.add(lang) then
    return false
  end

  vim.treesitter.start(buf, lang)
  if regex_highlight[lang] then
    vim.bo[buf].syntax = 'ON'
  end
  if not indent_disabled[lang] and vim.treesitter.query.get(lang, 'indents') then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  return true
end

local function attach_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      attach(buf)
    end
  end
end

local function missing(langs)
  local installed = require('nvim-treesitter').get_installed 'parsers'
  return vim.tbl_filter(function(lang)
    return not vim.list_contains(installed, lang)
  end, langs)
end

-- Parsers whose install was attempted this session, so failures are not
-- retried on every FileType event.
local attempted = {}

local function install(langs)
  langs = vim.tbl_filter(function(lang)
    return not attempted[lang]
  end, missing(langs))
  if #langs == 0 then
    return
  end
  if not has_cli() then
    warn_missing_cli()
    return
  end
  for _, lang in ipairs(langs) do
    attempted[lang] = true
  end
  require('nvim-treesitter').install(langs):await(vim.schedule_wrap(attach_all))
end

--- Blocking install of the configured parsers, for headless bootstrap scripts.
function M.install_sync(timeout)
  local langs = missing(M.parsers)
  if #langs == 0 then
    return
  end
  if not has_cli() then
    error 'tree-sitter CLI not found'
  end
  require('nvim-treesitter').install(langs, { summary = true }):wait(timeout or 300000)
  local failed = missing(M.parsers)
  if #failed > 0 then
    error('treesitter parsers failed to install: ' .. table.concat(failed, ', '))
  end
end

function M.setup()
  install(M.parsers)

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('config-treesitter', { clear = true }),
    callback = function(args)
      if attach(args.buf) or not auto_install then
        return
      end
      local lang = vim.treesitter.language.get_lang(args.match)
      if lang and require('nvim-treesitter.parsers')[lang] then
        install { lang }
      end
    end,
  })
end

return M
