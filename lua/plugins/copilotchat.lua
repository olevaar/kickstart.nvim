return {
  'CopilotC-Nvim/CopilotChat.nvim',
  branch = 'main',
  dependencies = {
    'zbirenbaum/copilot.lua',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  opts = {
    window = { layout = 'float', width = 0.6, height = 0.8, border = 'rounded' },
    mappings = {
      submit_prompt = { modes = { 'n', 'i', 'v' }, key = '<CR>' },
      close = 'q',
    },
  },
  keys = {
    {
      '<leader>cc',
      function()
        require('CopilotChat').toggle()
      end,
      desc = 'CopilotChat: Toggle',
    },
    {
      '<leader>cq',
      function()
        require('CopilotChat').quick_chat()
      end,
      desc = 'CopilotChat: Quick Chat',
    },
  },
}
