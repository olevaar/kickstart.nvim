return {
  'jim-at-jibba/nvim-redraft',
  event = 'VeryLazy',
  build = 'cd ts && npm install && npm run build',
  opts = {
    -- AI edits appear as conflict markers for review
    diff_mode = true,
    debug = true,
    llm = {
      provider = 'openai',
      model = 'gemini-2.5-flash',
      base_url = 'https://generativelanguage.googleapis.com/v1beta/openai/',
    },
    keys = {
      { '<leader>ae', function() require('nvim-redraft').edit() end, mode = 'v', desc = 'AI Edit Selection' },
      { '<leader>am', function() require('nvim-redraft').select_model() end, desc = 'Select AI Model' },
    },
  },
}
