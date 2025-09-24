local M = {}

M.keymaps = {
  { 'i', '<C-h>', '<Left>', { desc = 'Move left' } },
  { 'i', '<C-l>', '<Right>', { desc = 'Move right' } },
  { 'i', '<C-j>', '<Down>', { desc = 'Move down' } },
  { 'i', '<C-k>', '<Up>', { desc = 'Move up' } },
  { 'i', '<C-b>', '<Home>', { desc = 'Beginning of line' } },
  { 'i', '<C-e>', '<End>', { desc = 'End of line' } },
}


return M
