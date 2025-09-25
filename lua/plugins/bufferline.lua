return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VimEnter',
    init = function()
      vim.opt.termguicolors = true
    end,
    opts = {
      options = {
        mode = 'buffers', -- or "tabs"
        -- …any other bufferline options…
      },
    },
    keys = {
      { '<Tab>', '<Cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
      { '<S-Tab>', '<Cmd>BufferLineCyclePrev<CR>', desc = 'Prev buffer' },
    },
  },
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup {}
    end,
  },
}