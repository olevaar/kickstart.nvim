return {
  'akinsho/toggleterm.nvim',
  version = '*',
  event = 'VeryLazy',
  config = function()
    require('toggleterm').setup {
      direction = 'float',
      start_in_insert = true,
      persist_size = true,
      shade_terminals = true,
      shading_factor = 2,
      size = function(term)
        if term.direction == 'horizontal' then
          return 12
        elseif term.direction == 'vertical' then
          return math.floor(vim.o.columns * 0.4)
        else
          return 20
        end
      end,
      float_opts = { border = 'rounded' },
    }

    local Terminal = require('toggleterm.terminal').Terminal
    local term_float = Terminal:new { direction = 'float' }
    local term_horiz = Terminal:new { direction = 'horizontal' }
    local term_vert = Terminal:new { direction = 'vertical' }

    local function map(lhs, rhs, desc)
      vim.keymap.set({ 'n', 't' }, lhs, rhs, { silent = true, desc = desc })
    end

    map('<A-i>', function()
      term_float:toggle()
    end, 'Terminal (float)')
    map('<A-h>', function()
      term_horiz:toggle()
    end, 'Terminal (horizontal)')
    map('<A-v>', function()
      term_vert:toggle()
    end, 'Terminal (vertical)')

    vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { silent = true, desc = 'Exit terminal mode' })
    vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], { silent = true })
    vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], { silent = true })
    vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], { silent = true })
    vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], { silent = true })
  end,
}
