return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    file_types = { 'markdown' },
    exclude = {
      buftypes = {},
    },
  },
  config = function(_, opts)
    require('render-markdown').setup(opts)

    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = '*',
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if bufname:match '%[Magenta Chat%]' or bufname:match '%[Magenta Input%]' then
          vim.bo[args.buf].filetype = 'markdown'
        end
      end,
    })
  end,
}
