return {
  enabled = false,
  'RRethy/vim-illuminate',
  event = 'VeryLazy',
  opts = {
    delay = 200,
  },
  config = function(_, opts)
    require('illuminate').configure(opts)
  end,
}
