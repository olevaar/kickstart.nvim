return {
  'dlants/magenta.nvim',
  lazy = false,
  build = 'npm ci',
  opts = {
    profiles = {
      -- If you want a list of the models available for your copilot account,
      -- you can run the script under scripts/get_copilot_models.sh
      -- This will curl the copilot API and list the models you have access to.
      -- The token is read from ~/.config/github-copilot/apps.json, so you
      -- need to be authenticated with the copilot plugin first.
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
