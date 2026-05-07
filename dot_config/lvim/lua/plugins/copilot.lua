---@type LazySpec
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    -- VeryLazy (after VimEnter, once the UI is up) rather than InsertEnter:
    -- copilot.lua's setup() schedules its LSP startup via vim.schedule() and
    -- relies on a BufEnter autocmd it registers there. Loading on InsertEnter
    -- means the LSP races the first completion call (and :checkhealth shows
    -- "LSP client not available" before any insert has happened). VeryLazy
    -- gives the LSP time to come up before either is invoked.
    event = "VeryLazy",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = { markdown = true, help = true },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "fang2hou/blink-copilot" },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
}
