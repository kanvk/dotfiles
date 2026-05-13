---@type LazySpec
return {
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown" },
    keys = { { "<Leader>um", "<cmd>Markview Toggle<cr>", desc = "Toggle markview render" } },
    opts = {},
  },
  -- LazyVim's lang.markdown extra ships render-markdown.nvim. Both plugins
  -- conceal/render the same markdown elements and fight over conceallevel
  -- when active on the same buffer, so disable render-markdown here and
  -- let markview own the previewing.
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Window left" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Window down" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Window up" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Window right" },
    },
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {},
  },
  {
    "NMAC427/guess-indent.nvim",
    event = "BufReadPre",
    opts = {},
  },
  { "HiPhish/rainbow-delimiters.nvim", event = "BufReadPre" },
  { "andymass/vim-matchup", event = "BufReadPre" },
  -- Companion to nvim-spider from the same author: adds ~30 textobjects
  -- (iS/aS subword, iv/av value, ii/aI indentation, iU url, ...) on top of
  -- vim's built-ins.
  --
  -- Same disabled set and rebinds as the nvim side so muscle memory carries
  -- between distros. In lvim specifically:
  --   an/in is mini.ai's "around/inner NEXT <textobj-id>" prefix (e.g. `anq`
  --         = around-next-quote); keep it free of single-key takeover.
  --   r/R   are flash.nvim treesitter/remote motions in o/x mode.
  --   ak/ik, ao/io don't collide with anything load-bearing in lvim, but stay
  --         disabled here for parity with the nvim spec.
  -- `number` left unbound — LazyVim's dial extra (loaded via extras.lua)
  --         covers the `<C-a>`/`<C-x>` increment use case.
  {
    "chrisgrieser/nvim-various-textobjs",
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
        disabledDefaults = { "ak", "ik", "ao", "io", "an", "in", "r", "R" },
      },
    },
    keys = {
      { "aK", "<cmd>lua require('various-textobjs').key('outer')<cr>",        mode = { "o", "x" }, desc = "outer key textobj" },
      { "iK", "<cmd>lua require('various-textobjs').key('inner')<cr>",        mode = { "o", "x" }, desc = "inner key textobj" },
      { "aO", "<cmd>lua require('various-textobjs').anyBracket('outer')<cr>", mode = { "o", "x" }, desc = "outer any-bracket textobj" },
      { "iO", "<cmd>lua require('various-textobjs').anyBracket('inner')<cr>", mode = { "o", "x" }, desc = "inner any-bracket textobj" },
      { "gr", "<cmd>lua require('various-textobjs').restOfParagraph()<cr>",   mode = { "o", "x" }, desc = "rest of paragraph" },
      { "gR", "<cmd>lua require('various-textobjs').restOfIndentation()<cr>", mode = { "o", "x" }, desc = "rest of indentation" },
    },
  },
  -- w/e/b/ge stay vim-native (subword granularity gets in the way of moving
  -- across whole identifiers/funcs). Spider's subword motions are exposed on
  -- <Leader>s* for the occasional finer jump. Mirrors the nvim spec.
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "<Leader>sw",  "<cmd>lua require('spider').motion('w')<cr>",  mode = { "n", "x", "o" }, desc = "Next subword" },
      { "<Leader>se",  "<cmd>lua require('spider').motion('e')<cr>",  mode = { "n", "x", "o" }, desc = "Next end of subword" },
      { "<Leader>sb",  "<cmd>lua require('spider').motion('b')<cr>",  mode = { "n", "x", "o" }, desc = "Previous subword" },
      { "<Leader>sE",  "<cmd>lua require('spider').motion('ge')<cr>", mode = { "n", "x", "o" }, desc = "Previous end of subword" },
    },
    opts = {},
  },
  -- Lets `.` repeat plugin-defined operations (surround, etc.) in addition
  -- to vim's built-in changes. No-op until a plugin that calls
  -- `repeat#set()` is installed; tiny enough to keep loaded eagerly.
  { "tpope/vim-repeat", lazy = false },
  -- ys{motion}{char} adds, cs{old}{new} changes, ds{char} deletes surrounds.
  -- Pairs with vim-repeat so `.` re-applies the last surround edit.
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = { { "<Leader>uz", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" } },
    opts = {},
  },
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    keys = {
      { "<Leader>sR", function() require("spectre").open() end, desc = "Spectre (project search-replace)" },
    },
    opts = {},
  },
}
