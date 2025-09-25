return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
      vim.opt.termguicolors = true
    end,
    opts = {
      options = {
        mode = 'buffers', -- or "tabs"
        -- …any other bufferline options…
      },
    },
  },
  {
    'tiagovla/scope.nvim',
    config = function()
      require('scope').setup {}
    end,
  },
}
