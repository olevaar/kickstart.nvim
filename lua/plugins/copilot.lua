local function not_env_file()
  return not vim.fs.basename(vim.api.nvim_buf_get_name(0)):match '^%.env'
end

return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = {
    suggestion = { enabled = true, auto_trigger = true },
    panel = { enabled = false },
    -- Keep secrets out of Copilot: dotenv files are often detected as `sh`.
    filetypes = {
      env = false,
      dotenv = false,
      gitcommit = false,
      help = false,
      sh = not_env_file,
      ['*'] = true,
    },
  },
}
