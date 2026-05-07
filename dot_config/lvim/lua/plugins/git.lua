---@type LazySpec
return {
  {
    "tpope/vim-fugitive",
    cmd = {
      "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove",
      "GDelete", "GBrowse", "GRemove", "GRename", "Glgrep", "Gedit",
    },
    keys = {
      { "<Leader>ga", "<cmd>Git<cr>", desc = "Open Git status" },
      { "<Leader>gi", "<cmd>Gdiffsplit<cr>", desc = "Git diff split" },
      { "<Leader>go", "<cmd>Git log<cr>", desc = "Git log" },
    },
  },
  {
    "f-person/git-blame.nvim",
    cmd = { "GitBlameToggle", "GitBlameOpenCommitURL", "GitBlameCopyCommitURL", "GitBlameOpenFileURL" },
    keys = { { "<Leader>gB", "<cmd>GitBlameToggle<cr>", desc = "Toggle line blame" } },
    opts = { enabled = false },
  },
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    opts = {
      default_mappings = true,
      default_commands = true,
      list_opener = "copen",
    },
  },
}
