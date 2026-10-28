return {
  'folke/sidekick.nvim',
  opts = {
    cli = {
      win = {
        split = {
          width = 120,
        },
      },
      tools = {
        opencode = {
          -- OpenCode Desktop migrates the shared DB to a 2.x schema that the public
          -- 1.x CLI can't read, so prefer the newest CLI bundled with Desktop.
          cmd = (function()
            local newest, newest_version
            for _, base in ipairs { '~/.config/ai.opencode.desktop', '~/Library/Application Support/ai.opencode.desktop' } do
              for _, cli in ipairs(vim.fn.glob(vim.fn.expand(base) .. '/cli/*/opencode-cli', false, true)) do
                local version = vim.version.parse(cli:match '/cli/([^/]+)/opencode%-cli$' or '')
                if version and vim.fn.executable(cli) == 1 and (not newest_version or newest_version < version) then
                  newest, newest_version = cli, version
                end
              end
            end
            return { newest or 'opencode' }
          end)(),
        },
        copilot = {
          -- override the default command used to start the tool
          cmd = { 'copilot', '--alt-screen' },
        },
      },
    },
  },
  keys = {
    {
      '<leader>an',
      function()
        require('sidekick').nes_jump_or_apply()
      end,
      desc = 'Goto/Apply [N]ext Edit Suggestion',
    },
    {
      '<leader>aa',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick Toggle CLI',
    },
    {
      '<leader>as',
      function()
        require('sidekick.cli').select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = 'Select CLI',
    },
    {
      '<leader>ad',
      function()
        require('sidekick.cli').close()
      end,
      desc = 'Detach a CLI Session',
    },
    {
      '<leader>at',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      mode = { 'x', 'n' },
      desc = 'Send This',
    },
    {
      '<leader>af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'Send File',
    },
    {
      '<leader>av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      mode = { 'x' },
      desc = 'Send Visual Selection',
    },
    {
      '<leader>ap',
      function()
        require('sidekick.cli').prompt()
      end,
      mode = { 'n', 'x' },
      desc = 'Sidekick Select Prompt',
    },
  },
}
