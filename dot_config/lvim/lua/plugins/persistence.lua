---@type LazySpec
return {
  "folke/persistence.nvim",
  opts = {},
  keys = {
    { "<Leader>qs", function() require("persistence").load() end, desc = "Restore session for cwd" },
    { "<Leader>qS", function() require("persistence").select() end, desc = "Select session" },
    { "<Leader>ql", function() require("persistence").load { last = true } end, desc = "Restore last session" },
    { "<Leader>qd", function() require("persistence").stop() end, desc = "Don't save current session" },
  },
}
