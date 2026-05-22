---@type LazySpec
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        -- Net-new whichkey groups. The defaults from the upstream packs
        -- already label most leader and non-leader prefixes in n+x; the
        -- entries below add the rest and supply o-mode entries so
        -- operator-pending popups can name their sub-prefixes.
        { "<Leader>gH", group = "GitHub", mode = { "n", "x" } },
        { "<Leader>S",  group = "Subword", mode = { "n", "x", "o" } },
        { "<Leader>R",  group = "Replace", mode = { "n", "x" } },
        { "<Leader>O",  group = "Overseer", mode = "n" },

        -- o-mode (operator-pending) mirrors so c<x>, d<x>, y<x> popups label
        -- their sub-prefixes instead of falling back to "N keys".
        { "g", group = "goto", mode = "o" },
        { "[", group = "prev", mode = "o" },
        { "]", group = "next", mode = "o" },
        { "z", group = "fold", mode = "o" },
        -- <Leader> as a SUB-prefix inside operator-pending and visual mode:
        -- spider's <Leader>S* motions are mapped in {n,x,o} so c<Leader>Sw is
        -- a valid combo. The leader is the root popup in n-mode (doesn't need
        -- a sub-label) but in o/x it appears nested.
        { "<Leader>", group = "leader", mode = { "o", "x" } },
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
      -- <Leader>cR is the LazyVim-native slot (Code → Rename); <Leader>fR
      -- is aliased for AstroNvim parity so muscle memory carries between
      -- configs.
      { "<Leader>cR",  function() Snacks.rename.rename_file() end, desc = "Rename file (LSP-aware)" },
      { "<Leader>fR",  function() Snacks.rename.rename_file() end, desc = "Rename file (LSP-aware)" },
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
