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
    "sindrets/diffview.nvim",
    keys = {
      { "<Leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<Leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
    },
  },
}
