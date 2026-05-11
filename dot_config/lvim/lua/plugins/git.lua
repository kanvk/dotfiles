---@type LazySpec
return {
  {
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GDelete",
      "GBrowse",
      "GRemove",
      "GRename",
      "Glgrep",
      "Gedit",
    },
    keys = {
      { "<leader>ga", "<cmd>Git<cr>", desc = "Open Git status" },
      { "<leader>gi", "<cmd>Gdiffsplit<cr>", desc = "Git diff split" },
      { "<leader>go", "<cmd>Git log<cr>", desc = "Git log" },
    },
  },
  {
    -- cmd entries make :Diffview* tab-complete before any keybind has fired
    -- (otherwise lazy.nvim won't load the plugin until <leader>gd/gh/gl).
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview (working tree)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>gl", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo-wide)" },
    },
  },
  {
    "f-person/git-blame.nvim",
    cmd = { "GitBlameToggle", "GitBlameOpenCommitURL", "GitBlameCopyCommitURL", "GitBlameOpenFileURL" },
    keys = { { "<leader>gB", "<cmd>GitBlameToggle<cr>", desc = "Toggle line blame" } },
    opts = { enabled = false },
  },
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    opts = {
      -- Mappings are buffer-local to conflicted files (per upstream README),
      -- so they don't shadow vim's built-in c0 / cb / ct{char} motions
      -- elsewhere. In a conflict: co (ours), ct (theirs), cb (both), c0 (none).
      default_mappings = true,
      default_commands = true, -- :GitConflictListQf, :GitConflictRefresh, :GitConflictNextConflict, :GitConflictPrevConflict
      list_opener = "copen",
    },
  },
}
