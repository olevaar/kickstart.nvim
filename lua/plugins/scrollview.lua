return {
  'dstein64/nvim-scrollview',
  event = 'BufRead',
  config = function()
    require('scrollview').setup()
  end,
}
