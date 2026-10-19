-- This config is not LazyVim, so nothing consumes the
-- { "LazyVim/LazyVim", opts = { colorscheme = ... } } entry that Omarchy's
-- theme spec (lua/plugins/theme.lua -> current/theme/neovim.lua) uses to pick
-- the colorscheme. Disable that entry so lazy never loads LazyVim itself, and
-- apply the colorscheme at startup here instead. Hot-reloading on theme change
-- is still handled by omarchy-theme-hotreload.lua, which reads the raw spec.
local function omarchy_colorscheme()
  local ok, spec = pcall(require, 'plugins.theme')
  if not ok or type(spec) ~= 'table' then
    return nil
  end
  for _, s in ipairs(spec) do
    if s[1] == 'LazyVim/LazyVim' and s.opts and s.opts.colorscheme then
      return s.opts.colorscheme
    end
  end
end

return {
  { 'LazyVim/LazyVim', enabled = false },
  {
    name = 'omarchy-theme-startup',
    dir = vim.fn.stdpath 'config',
    lazy = false,
    priority = 1000,
    config = function()
      local colorscheme = omarchy_colorscheme() or 'catppuccin'
      if not pcall(vim.cmd.colorscheme, colorscheme) then
        pcall(vim.cmd.colorscheme, 'catppuccin')
      end
    end,
  },
}
