return {
  'yetone/avante.nvim',
  build = (vim.fn.has 'win32' ~= 0) and 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false' or 'make',
  event = 'VeryLazy',
  version = false,
  opts = {
    providers = {
      ['gemini-cli'] = {
        command = 'gemini', -- installed by @google/gemini-cli
        args = { '--experimental-acp' }, -- ACP mode
        env = {
          NODE_NO_WARNINGS = '1',
          GEMINI_API_KEY = os.getenv 'GEMINI_API_KEY',
        },
      },
      copilot = {},
    },
    -- optional niceties
    behaviour = { auto_suggestions = false },
    mappings = { auto_set_keymaps = true },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = { file_types = { 'markdown', 'Avante' } },
      ft = { 'markdown', 'Avante' },
    },
  },
  config = function(_, opts)
    local providers = vim.tbl_keys(opts.providers)
    local current_provider_index = 1

    local function set_provider()
      opts.provider = providers[current_provider_index]
      require('avante').setup(opts)
      vim.notify('Avante provider changed to ' .. opts.provider)
    end

    vim.keymap.set('n', '<leader>ap', function()
      current_provider_index = current_provider_index % #providers + 1
      set_provider()
    end, { desc = 'Switch Avante provider' })

    vim.keymap.set('n', '<leader>op', function()
      vim.notify('Current Avante provider: ' .. opts.provider)
    end, { desc = 'Show current Avante provider' })

    set_provider()
  end,
}
