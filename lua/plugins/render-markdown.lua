return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    file_types = { 'markdown' },
    -- Allow rendering in nofile buffers (needed for Magenta output)
    exclude = {
      buftypes = {},
    },
  },
}
