-- Uses Omarchy's current Neovim theme when Omarchy is installed, otherwise
-- catppuccin. omarchy-theme.lua applies it at startup and on theme changes.
local omarchy_theme = require('configs.omarchy').theme_file

if vim.fn.filereadable(omarchy_theme) == 1 then
  local ok, spec = pcall(dofile, omarchy_theme)
  if ok and type(spec) == 'table' then
    return spec
  end
  vim.notify('Could not load Omarchy theme ' .. omarchy_theme .. ': ' .. tostring(spec), vim.log.levels.WARN)
end

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
  },
  {
    'LazyVim/LazyVim',
    opts = {
      colorscheme = 'catppuccin',
    },
  },
}
