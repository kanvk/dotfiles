-- Treesitter-driven split/join for blocks. Turns single-line dicts/lists/
-- function-calls into multi-line and back. Pairs with refactoring.nvim
-- under <Leader>r* and replaces vim's vanilla `gJ` (join without space)
-- with the smarter toggle.

---@type LazySpec
return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
  keys = {
    { "gJ", function() require("treesj").toggle() end, desc = "Treesj toggle (split/join block)" },
    { "<Leader>rj", function() require("treesj").join() end, desc = "Treesj join block" },
    { "<Leader>rs", function() require("treesj").split() end, desc = "Treesj split block" },
  },
  opts = { use_default_keymaps = false, max_join_length = 240 },
}
