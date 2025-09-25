return {
  'kdheepak/lazygit.nvim',
  cmd = 'LazyGit',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('telescope').load_extension 'lazygit'
  end,
  keys = {
    { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'Open LazyGit' },
  },
}
