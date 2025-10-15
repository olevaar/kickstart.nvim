return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',

    'nvim-neotest/nvim-nio',

    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    'leoluz/nvim-dap-go',

    -- Load dap-kotlin only for Kotlin buffers (prevents early setup on VimEnter/LspAttach)
    { 'Mgenuit/nvim-dap-kotlin', ft = 'kotlin' },
  },
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
    {
      '<leader>tr',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve',
        'kotlin-debug-adapter',
      },
    }

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open

    require('dap-go').setup {
      delve = {
        detached = vim.fn.has 'win32' == 0,
      },
    }

    pcall(require, 'debug.java')

    -- 👉 Kotlin: set up only when a Kotlin buffer opens
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'kotlin',
      callback = function()
        local ok, dap_kotlin = pcall(require, 'dap-kotlin')
        if not ok then
          return
        end
        -- Ensure the configurations table exists to avoid pairs(nil)
        dap.configurations.kotlin = dap.configurations.kotlin or {}
        dap_kotlin.setup {
          dap = dap, -- pass dap explicitly (dap-kotlin will use it if provided)
          -- put your dap-kotlin opts here if you have any
        }
      end,
    })
  end,
}
