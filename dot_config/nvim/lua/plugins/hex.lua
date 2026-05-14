-- xxd-backed hex view. Lazy on the three :Hex* commands and on
-- `nvim -b <file>` (binary mode is set globally before BufReadPre fires,
-- so checking vim.o.binary inside init() is enough to force-load before
-- the plugin's BufReadPre hook needs to run).

---@type LazySpec
return {
  "RaafatTurki/hex.nvim",
  cmd = { "HexDump", "HexAssemble", "HexToggle" },
  init = function()
    if vim.o.binary then require("lazy").load { plugins = { "hex.nvim" } } end
  end,
  opts = {},
}
