-- Git config
-- gitsigns ships with AstroNvim core; fugitive and git-conflict are
-- user additions (no AstroCommunity pack provides git-conflict).

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
    "akinsho/git-conflict.nvim",
    event = "User AstroFile",
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
