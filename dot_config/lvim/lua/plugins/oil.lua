-- Directory-as-buffer editor. Complements neo-tree (tree view) and
-- snacks.picker (find): oil lets you rename/delete/create files by
-- editing a buffer like text.
--
-- Loads lazily on the keybinds and on :Oil. `default_file_explorer =
-- false` keeps neo-tree the handler for `nvim <dir>` invocations;
-- oil is opt-in via the keys below.

---@type LazySpec
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  cmd = "Oil",
  keys = {
    { "<Leader>-",  function() require("oil").open() end, desc = "Open parent directory (oil)" },
    { "<Leader>fd", function() require("oil").open(vim.fn.getcwd()) end, desc = "Find in directory (oil)" },
  },
  opts = {
    default_file_explorer = false,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = { show_hidden = true },
  },
}
