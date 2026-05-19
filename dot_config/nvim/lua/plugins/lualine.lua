-- Lualine is installed but never set up here; heirline renders the statusline.
-- statusline_palette.lua borrows `lualine.themes.auto` as a final-tier color
-- sampler when the active colorscheme doesn't ship its own lualine theme.
return {
  "nvim-lualine/lualine.nvim",
  lazy = true,
}
