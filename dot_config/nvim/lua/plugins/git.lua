-- Git config

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
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
  },
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
  },
}
