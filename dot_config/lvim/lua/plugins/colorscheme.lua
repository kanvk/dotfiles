---@type LazySpec
return {
  -- LazyVim's default colorscheme is tokyonight-moon; override to -night to
  -- match the AstroNvim config's tokyonight-night (set there via AstroUI).
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
