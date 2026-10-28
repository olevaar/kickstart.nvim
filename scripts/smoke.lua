-- Headless smoke test for this config. Run from the repository root:
--   nvim --headless -c 'luafile scripts/smoke.lua'
-- Exits non-zero and prints the failures if any check fails.
local failures = {}

local function check(ok, msg)
  if not ok then
    table.insert(failures, msg)
  end
end

local function finish()
  if #failures > 0 then
    io.stderr:write('FAIL\n  ' .. table.concat(failures, '\n  ') .. '\n')
    vim.cmd 'cquit 1'
  end
  io.stdout:write 'OK\n'
  vim.cmd 'qa!'
end

local ok, err = pcall(function()
  local messages = vim.api.nvim_exec2('messages', { output = true }).output
  check(not messages:find 'E%d+:' and not messages:find 'Error', 'startup produced errors:\n' .. messages)
  check(vim.g.colors_name ~= nil, 'no colorscheme applied')

  check(vim.tbl_get(vim.lsp.config.lua_ls, 'settings', 'Lua', 'completion', 'callSnippet') == 'Replace', 'lua_ls settings not applied')
  check(
    vim.tbl_get(vim.lsp.config.ts_ls, 'capabilities', 'textDocument', 'completion', 'completionItem', 'snippetSupport') == true,
    'cmp capabilities not applied to ts_ls'
  )
  check(not vim.lsp.is_enabled 'jdtls', 'jdtls is auto-enabled (nvim-jdtls must be the only starter)')

  check(vim.fn.maparg('<Tab>', 'n', false, true).desc == 'Next buffer', '<Tab> in normal mode is not bufferline')
  check(vim.fn.maparg('<leader>cf', 'n') ~= '', '<leader>cf (format) is not mapped')
  check(vim.fn.maparg('<leader>ae', 'v') ~= '', '<leader>ae (redraft) is not mapped')
  check(vim.fn.maparg('<leader>an', 'n') ~= '', '<leader>an (sidekick next edit) is not mapped')
  check(vim.fn.maparg('<C-h>', 't') == '', '<C-h> is still mapped in terminal mode')

  vim.cmd.edit 'init.lua'
  check(vim.fn.exists ':GuessIndent' == 2, 'guess-indent is not set up')
  check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, 'treesitter highlighting is not active for Lua')

  if vim.fn.executable 'lua-language-server' == 1 then
    local attached = vim.wait(30000, function()
      return #vim.lsp.get_clients { bufnr = 0, name = 'lua_ls' } > 0
    end, 200)
    check(attached, 'lua_ls did not attach to init.lua')
    if attached then
      check(vim.fn.maparg('of', 'n') == '', "buffer-local 'of' mapping delays 'o'")
      check(vim.fn.maparg('<leader>e', 'n') ~= '', '<leader>e (diagnostic float) is not mapped')
    end
  end
end)

check(ok, 'smoke test raised: ' .. tostring(err))
finish()
