local M = {}

M.keymaps = {
  { 'i', '<C-h>', '<Left>', { desc = 'Move left' } },
  { 'i', '<C-l>', '<Right>', { desc = 'Move right' } },
  { 'i', '<C-j>', '<Down>', { desc = 'Move down' } },
  { 'i', '<C-k>', '<Up>', { desc = 'Move up' } },
  { 'i', '<C-b>', '<Home>', { desc = 'Beginning of line' } },
  { 'i', '<C-e>', '<End>', { desc = 'End of line' } },
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>' },
  { 'n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' } },
  { 'n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' } },
  { 'n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' } },
  { 'n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' } },
  { 'n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' } },
  { 'n', '<leader>rn', vim.lsp.buf.rename, { desc = '[R]e[n]ame' } },
  { { 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code [A]ction' } },
  { 'n', '<leader>dh', ':diffget //2<CR>', { desc = 'Diff get from left (//2)' } },
  { 'n', '<leader>dl', ':diffget //3<CR>', { desc = 'Diff get from right (//3)' } },
}

return M
