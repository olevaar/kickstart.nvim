return {
  'sudormrfbin/cheatsheet.nvim',
  config = function()
    require('cheatsheet').setup {}

    -- optional: keybind to open cheatsheet
    vim.keymap.set('n', '<leader>ch', ':Cheatsheet<CR>', { desc = 'Open cheatsheet' })
  end,
}
