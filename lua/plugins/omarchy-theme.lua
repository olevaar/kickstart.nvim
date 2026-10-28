-- Applies the theme spec from lua/plugins/theme.lua (Omarchy's current theme, or
-- catppuccin) at startup and again whenever Omarchy switches themes.
--
-- This config is not LazyVim, so nothing consumes the
-- { "LazyVim/LazyVim", opts = { colorscheme = ... } } entry Omarchy's theme spec
-- uses to pick the colorscheme. Disable that entry so lazy never loads LazyVim,
-- and read the colorscheme from the raw spec here instead.
--
-- Startup and hot-reload must be one spec: lazy merges local specs that share a
-- `dir`, so a second spec for stdpath('config') would replace this config.

local function theme_spec()
  package.loaded['plugins.theme'] = nil
  local ok, spec = pcall(require, 'plugins.theme')
  if ok and type(spec) == 'table' then
    return spec
  end
end

local function colorscheme_of(spec)
  for _, s in ipairs(spec or {}) do
    if s[1] == 'LazyVim/LazyVim' and s.opts and s.opts.colorscheme then
      return s.opts.colorscheme
    end
  end
end

local function apply_startup_theme()
  local colorscheme = colorscheme_of(theme_spec()) or 'catppuccin'
  if not pcall(vim.cmd.colorscheme, colorscheme) then
    pcall(vim.cmd.colorscheme, 'catppuccin')
  end
end

local function reload_theme()
  local spec = theme_spec()
  local colorscheme = colorscheme_of(spec)
  if not colorscheme then
    return
  end

  local theme_plugin_name
  for _, s in ipairs(spec) do
    if s[1] and s[1] ~= 'LazyVim/LazyVim' then
      theme_plugin_name = s.name or s[1]
      break
    end
  end
  local plugins = require('lazy.core.config').plugins
  local theme_plugin = theme_plugin_name and plugins[theme_plugin_name]

  vim.cmd 'highlight clear'
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
  -- Light themes set this back to light themselves.
  vim.o.background = 'dark'

  if theme_plugin then
    -- Unload the plugin's modules so the new theme's setup() takes effect.
    require('lazy.core.util').walkmods(theme_plugin.dir .. '/lua', function(modname)
      package.loaded[modname] = nil
      package.preload[modname] = nil
    end)
  end

  -- If the old and new theme share a plugin (e.g. generic themes on
  -- aether.nvim), lazy won't rerun setup() on a spec reload and keeps the old
  -- resolved opts, so fully reload it to reapply setup() with the new opts.
  if theme_plugin and theme_plugin._.loaded then
    require('lazy.core.loader').reload(theme_plugin)
  else
    require('lazy.core.loader').colorscheme(colorscheme)
  end

  vim.defer_fn(function()
    pcall(vim.cmd.colorscheme, colorscheme)
    vim.cmd 'redraw!'
  end, 5)
end

return {
  { 'LazyVim/LazyVim', enabled = false },
  {
    name = 'omarchy-theme',
    dir = vim.fn.stdpath 'config',
    lazy = false,
    priority = 1000,
    config = function()
      apply_startup_theme()

      vim.api.nvim_create_autocmd('User', {
        pattern = 'LazyReload',
        callback = vim.schedule_wrap(reload_theme),
      })

      -- lazy's change detection only watches lua/plugins/*, so watch Omarchy's
      -- theme file too and reload the spec the same way when it changes.
      local theme_file = require('configs.omarchy').theme_file
      local poll = assert(vim.uv.new_fs_poll())
      poll:start(
        theme_file,
        2000,
        vim.schedule_wrap(function(err)
          if not err then
            require('lazy.manage.reloader').reload { { file = theme_file, what = 'changed' } }
          end
        end)
      )
    end,
  },
}
