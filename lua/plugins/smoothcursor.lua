return {
  'gen740/SmoothCursor.nvim',
  lazy = false,
  config = function()
    vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#FFD400' }) -- gold head
    vim.api.nvim_set_hl(0, 'SmoothCursorRed', { fg = '#E06C75' })
    vim.api.nvim_set_hl(0, 'SmoothCursorOrange', { fg = '#D19A66' })
    vim.api.nvim_set_hl(0, 'SmoothCursorYellow', { fg = '#E5C07B' })
    vim.api.nvim_set_hl(0, 'SmoothCursorGreen', { fg = '#98C379' })
    vim.api.nvim_set_hl(0, 'SmoothCursorAqua', { fg = '#56B6C2' })
    vim.api.nvim_set_hl(0, 'SmoothCursorBlue', { fg = '#61AFEF' })
    vim.api.nvim_set_hl(0, 'SmoothCursorPurple', { fg = '#C678DD' })

    ---@diagnostic disable-next-line: missing-fields
    require('smoothcursor').setup {
      type = 'default',

      priority = 10,

      cursor = '',
      texthl = 'SmoothCursor',
      linehl = nil,

      fancy = {
        enable = true,
        head = { cursor = '▷', texthl = 'SmoothCursor', linehl = nil },
        body = {
          { cursor = '󰝥', texthl = 'SmoothCursorRed' },
          { cursor = '󰝥', texthl = 'SmoothCursorOrange' },
          { cursor = '●', texthl = 'SmoothCursorYellow' },
          { cursor = '●', texthl = 'SmoothCursorGreen' },
          { cursor = '•', texthl = 'SmoothCursorAqua' },
          { cursor = '.', texthl = 'SmoothCursorBlue' },
          { cursor = '.', texthl = 'SmoothCursorPurple' },
        },
        tail = { cursor = nil, texthl = 'SmoothCursor' },
      },

      autostart = true,
      always_redraw = true,
      speed = 35,
      intervals = 18,
      threshold = 0,
      max_threshold = 9999,
      timeout = 3000,
      disable_float_win = false,
      enabled_filetypes = nil,
      disabled_filetypes = { 'TelescopePrompt', 'alpha', 'starter' },
    }
  end,
}
