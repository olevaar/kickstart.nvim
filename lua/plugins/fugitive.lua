return {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'G', 'GBrowse' },
  keys = {
    { '<leader>gs', '<cmd>Git<cr>', desc = 'Git status' },
    { '<leader>gd', '<cmd>vert Gvdiffsplit<cr>', desc = 'Git diff' },
    { '<leader>gv', '<cmd>vert Gvdiffsplit!<cr>', desc = 'Git diff (three-way)' },
    { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
  },
}
