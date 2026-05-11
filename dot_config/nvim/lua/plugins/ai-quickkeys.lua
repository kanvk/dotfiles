-- Additive layer on top of `astrocommunity.ai.sidekick-nvim`, which uses
-- `<Leader>A*` (capital A) per AstroNvim's sub-namespace convention. These
-- map the three CLIs I actually reach for and a "send current line" shortcut.
---@type LazySpec
return {
  {
    "folke/sidekick.nvim",
    keys = {
      { "<Leader>Ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Sidekick: Claude" },
      { "<Leader>Ao", function() require("sidekick.cli").toggle({ name = "codex",  focus = true }) end, desc = "Sidekick: Codex" },
      { "<Leader>Ag", function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end, desc = "Sidekick: Gemini" },
      { "<Leader>Al", function() require("sidekick.cli").send({ msg = "{line}" }) end, desc = "Sidekick: send current line" },
    },
  },
}
