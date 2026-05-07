---@type LazySpec
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<Leader>gH", group = "GitHub" },
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<Leader>.",   function() Snacks.scratch() end, desc = "Open scratchpad" },
      { "<Leader>fS",  function() Snacks.scratch.select() end, desc = "Find scratchpads" },
      { "<Leader>fz",  function() Snacks.picker.zoxide() end, desc = "Find via zoxide" },
      { "<Leader>fu",  function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<Leader>gHi", function() Snacks.picker.gh_issue() end, desc = "Issues (open)" },
      { "<Leader>gHI", function() Snacks.picker.gh_issue { state = "all" } end, desc = "Issues (all)" },
      { "<Leader>gHp", function() Snacks.picker.gh_pr() end, desc = "Pull requests (open)" },
      { "<Leader>gHP", function() Snacks.picker.gh_pr { state = "all" } end, desc = "Pull requests (all)" },
      { "<Leader>gO",  function() Snacks.gitbrowse() end, desc = "Open on remote", mode = { "n", "x" } },
      { "<Leader>cR",  function() Snacks.rename.rename_file() end, desc = "Rename file (LSP-aware)" },
    },
  },
  {
    -- cmd entries make :Diffview* tab-complete (and lazy-load the plugin)
    -- before any keybind has fired. <Leader>gl is bound in config/keymaps.lua
    -- so it wins over LazyVim's default Snacks log picker; the cmd entry
    -- still triggers plugin load when that mapping fires.
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
    keys = {
      { "<Leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview (working tree)" },
      { "<Leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
    },
  },
}
