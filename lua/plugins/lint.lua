return {

  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        kotlin = { 'ktlint' },
        markdown = { 'markdownlint' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          local is_magenta = vim.b.magenta_input_buffer or vim.bo.filetype == 'magenta'
          if vim.bo.modifiable and not is_magenta then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
