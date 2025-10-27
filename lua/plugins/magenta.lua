return {
  'dlants/magenta.nvim',
  lazy = false,
  build = 'npm ci',
  opts = {
    profiles = {
      {
        name = 'copilot-claude',
        provider = 'copilot',
        -- gpt-4.1
        -- gpt-5-mini
        -- gpt-5
        -- gpt-3.5-turbo
        -- gpt-3.5-turbo-0613
        -- gpt-4o-mini
        -- gpt-4o-mini-2024-07-18
        -- gpt-4
        -- gpt-4-0613
        -- gpt-4o
        -- gpt-4o-2024-11-20
        -- gpt-4o-2024-05-13
        -- gpt-4-o-preview
        -- gpt-4o-2024-08-06
        -- o3-mini
        -- o3-mini-2025-01-31
        -- o3-mini-paygo
        -- grok-code-fast-1
        -- text-embedding-ada-002
        -- text-embedding-3-small
        -- text-embedding-3-small-inference
        -- claude-3.5-sonnet
        -- claude-3.7-sonnet
        -- claude-3.7-sonnet-thought
        -- claude-sonnet-4
        -- claude-sonnet-4.5
        -- claude-haiku-4.5
        -- gemini-2.0-flash-001
        -- gemini-2.5-pro
        -- gpt-4.1-2025-04-14

        model = 'claude-sonnet-4.5',
        fastModel = 'claude-haiku-4.5',
      },
      {
        name = 'copilot-gpt',
        provider = 'copilot',
        model = 'gpt-5',
        fastModel = 'gpt-5-mini',
      },
      {
        name = 'copilot-gemini',
        provider = 'copilot',
        model = 'gemini-2.5-pro',
        fastModel = 'gemini-2.0-flash-001',
      },
    },
    chimeVolume = 0.0,
  },
}
