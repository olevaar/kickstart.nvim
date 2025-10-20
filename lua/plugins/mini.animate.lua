return {
  'echasnovski/mini.animate',
  event = 'VeryLazy',
  config = function()
    require('mini.animate').setup {
      scroll = {
        enable = true,
        timing = require('mini.animate').gen_timing.linear { duration = 50, unit = 'total' },
      },
      cursor = {
        enable = false,
        --        path = require('mini.animate').gen_path.line {
        --        predicate = function()
        --      return true
        --   end,
        --   },
        -- timing = require('mini.animate').gen_timing.linear { duration = 50, unit = 'total' },
      },
      resize = {
        enable = true,
        timing = require('mini.animate').gen_timing.linear { duration = 50, unit = 'total' },
      },
    }
  end,
}
