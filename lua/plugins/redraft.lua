return {
  'jim-at-jibba/nvim-redraft',
  event = 'VeryLazy',
  build = 'cd ts && npm install && npm run build',
  opts = {
    -- AI edits appear as conflict markers for review
    diff_mode = true,
    debug = true,
    llm = {
      -- Note: base_url is applied to the OpenAI provider globally in the current plugin version
      base_url = 'https://generativelanguage.googleapis.com/v1beta/openai/',
      models = {
        {
          provider = 'openai',
          model = 'gemini-3.1-pro-preview',
          label = 'Gemini 3.1 Pro',
        },
        {
          provider = 'copilot',
          model = 'gpt-5.2',
          label = 'GitHub Copilot (GPT 5.2)',
        },
      },
      default_model_index = 1,
    },
    keys = {
      {
        '<leader>ae',
        function()
          require('nvim-redraft').edit()
        end,
        mode = 'v',
        desc = 'AI Edit Selection',
      },
      {
        '<leader>am',
        function()
          require('nvim-redraft').select_model()
        end,
        desc = 'Select AI Model',
      },
    },
  },
}
