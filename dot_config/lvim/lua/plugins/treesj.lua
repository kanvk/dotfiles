-- Treesitter-driven split/join for blocks. Turns single-line dicts/lists/
-- function-calls into multi-line and back. Vim's vanilla `gJ` (join
-- without space) is the rebind target.
--
-- lvim-specific: LazyVim's <Leader>rs is refactoring.select_refactor —
-- skip leader-prefixed treesj bindings to respect LazyVim's <Leader>r*
-- philosophy. Just `gJ` — identical key between configs.

---@type LazySpec
return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
  keys = {
    { "gJ", function() require("treesj").toggle() end, desc = "Treesj toggle (split/join block)" },
  },
  opts = { use_default_keymaps = false, max_join_length = 240 },
}
