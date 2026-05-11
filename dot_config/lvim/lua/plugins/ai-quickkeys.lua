-- Additive layer on top of LazyVim's `extras.ai.sidekick`, which uses
-- `<leader>a*` (lowercase) per LazyVim's namespace convention. These map the
-- three CLIs I actually reach for and a "send current line" shortcut.
---@type LazySpec
return {
  "folke/sidekick.nvim",
  keys = {
    { "<leader>ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Sidekick: Claude" },
    { "<leader>ao", function() require("sidekick.cli").toggle({ name = "codex",  focus = true }) end, desc = "Sidekick: Codex" },
    { "<leader>ag", function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end, desc = "Sidekick: Gemini" },
    { "<leader>al", function() require("sidekick.cli").send({ msg = "{line}" }) end, desc = "Sidekick: send current line" },
  },
}
