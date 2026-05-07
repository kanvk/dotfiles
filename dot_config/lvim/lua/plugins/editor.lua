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
  { "nvim-treesitter/nvim-treesitter-context", event = "BufReadPre", opts = {} },
  { "HiPhish/rainbow-delimiters.nvim", event = "BufReadPre" },
  { "andymass/vim-matchup", event = "BufReadPre" },
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
