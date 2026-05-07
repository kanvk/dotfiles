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
    -- AstroNvim's gitsigns spec sets buffer-local <Leader>gd (diffthis) and
    -- <Leader>gl (blame_line), which shadow our diffview mappings in tracked
    -- files. Drop both; the corresponding `:Gitsigns diffthis` and
    -- `:Gitsigns blame_line` ex-commands remain available, and full blame is
    -- still on <Leader>gL.
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local prev_on_attach = opts.on_attach
      opts.on_attach = function(bufnr)
        if prev_on_attach then prev_on_attach(bufnr) end
        pcall(vim.keymap.del, "n", "<Leader>gd", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<Leader>gl", { buffer = bufnr })
      end
      return opts
    end,
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
