local M = {}

local modes = { "normal", "insert", "visual", "replace", "command", "terminal", "inactive" }

local lualine_mode = {
  n = "normal", no = "normal", nov = "normal", noV = "normal",
  ["no\22"] = "normal", niI = "normal", niR = "normal", niV = "normal",
  nt = "normal", ntT = "normal",
  v = "visual", vs = "visual", V = "visual", Vs = "visual",
  ["\22"] = "visual", ["\22s"] = "visual",
  s = "visual", S = "visual", ["\19"] = "visual",
  i = "insert", ic = "insert", ix = "insert",
  R = "replace", Rc = "replace", Rx = "replace",
  Rv = "replace", Rvc = "replace", Rvx = "replace",
  c = "command", cv = "command", ce = "command",
  r = "replace", rm = "command", ["r?"] = "command",
  ["!"] = "normal", t = "terminal",
}

function M.normalize_color(color)
  if type(color) == "number" then return string.format("#%06x", color) end
  return color
end

function M.hl_color(group, attr, fallback)
  return M.normalize_color(require("astroui").get_hlgroup(group)[attr]) or fallback
end

function M.lualine_theme()
  local name = vim.g.colors_name
  if name and name ~= "" then
    local ok, theme = pcall(require, "lualine.themes." .. name)
    if ok and type(theme) == "table" then return theme end
  end
  -- Fallback: lualine's built-in `auto` samples highlight groups at require time.
  local ok, auto = pcall(require, "lualine.themes.auto")
  if ok and type(auto) == "table" then return auto end
end

function M.current_lualine_mode()
  local mode = vim.api.nvim_get_mode().mode
  return lualine_mode[mode] or "normal"
end

function M.astro_mode_overrides()
  return {
    nt = { "NORMAL", "normal" },
    ntT = { "NORMAL", "normal" },
    Rvc = { "V-REPLACE", "replace" },
    Rvx = { "V-REPLACE", "replace" },
    r = { "REPLACE", "replace" },
    rm = { "MORE", "command" },
    ["r?"] = { "CONFIRM", "command" },
    ["!"] = { "SHELL", "normal" },
  }
end

function M.lualine_section(theme, mode, section)
  if type(theme) ~= "table" or type(theme.normal) ~= "table" then return end

  local mode_theme = theme[mode]
  -- Many lualine themes omit a `terminal` block; fall back to `insert` instead
  -- of `normal` to preserve the typical lualine convention.
  if mode == "terminal" and type(mode_theme) ~= "table" and type(theme.insert) == "table" then
    mode_theme = theme.insert
  end
  if type(mode_theme) == "table" and mode_theme[section] then return mode_theme[section] end

  return theme.normal[section]
end

function M.lualine_attr(theme, mode, section, attr, fallback)
  local section_hl = M.lualine_section(theme, mode, section)
  local color

  if type(section_hl) == "table" then
    color = section_hl[attr]
  elseif type(section_hl) == "string" then
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = section_hl, link = false })
    if ok and hl then color = hl[attr] end
  end

  return M.normalize_color(color) or fallback
end

function M.apply_lualine_mode_colors(colors)
  colors = colors or {}
  local theme = M.lualine_theme()
  if not theme then return colors end

  for _, mode in ipairs(modes) do
    colors[mode] = M.lualine_attr(theme, mode, "a", "bg", colors[mode])
  end
  colors.mode_fg = M.lualine_attr(theme, "normal", "a", "fg", colors.mode_fg)

  return colors
end

-- Module-level side effect: registers a ColorScheme autocmd to invalidate
-- lualine's auto theme cache (it samples highlight groups at require time
-- and stays cached in package.loaded). `clear = true` on the augroup makes
-- re-require idempotent.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("StatuslinePaletteRefresh", { clear = true }),
  callback = function() package.loaded["lualine.themes.auto"] = nil end,
})

return M
