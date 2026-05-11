-- Copilot config

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
      -- The bundled `@github/copilot` LSP ships a custom HTTP fetcher whose
      -- headers wrapper is case-sensitive; on Node 26+ it returns null for
      -- `content-type` and breaks signInInitiate + embedding fetches with
      -- "Response content-type is missing (status=200)". Pin the LSP to a
      -- side-by-side Node 22 (keg-only brew formula) when available.
      copilot_node_command = (function()
        local prefix = vim.env.HOMEBREW_PREFIX
        if prefix and prefix ~= "" then
          local p = prefix .. "/opt/node@22/bin/node"
          if vim.fn.executable(p) == 1 then return p end
        end
        return "node"
      end)(),
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
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
