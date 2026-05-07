---@type LazySpec
return {
  { "stevearc/resession.nvim", enabled = false },

  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      if opts.mappings and opts.mappings.n then
        for _, k in ipairs({
          "<Leader>S",
          "<Leader>Sl",
          "<Leader>Ss",
          "<Leader>SS",
          "<Leader>St",
          "<Leader>Sd",
          "<Leader>SD",
          "<Leader>Sf",
          "<Leader>SF",
          "<Leader>S.",
        }) do
          opts.mappings.n[k] = false
        end
      end
      if opts.autocmds then
        opts.autocmds.resession_auto_save = false
      end
    end,
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<Leader>qs", function() require("persistence").load() end, desc = "Restore session for cwd" },
      { "<Leader>qS", function() require("persistence").select() end, desc = "Select session" },
      { "<Leader>ql", function() require("persistence").load { last = true } end, desc = "Restore last session" },
      { "<Leader>qd", function() require("persistence").stop() end, desc = "Don't save current session" },
    },
  },
}
