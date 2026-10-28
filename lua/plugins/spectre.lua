return {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Spectre',
  keys = {
    { '<leader>S', '<cmd>Spectre<cr>', desc = 'Open Spectre' },
  },
  opts = {},
}
