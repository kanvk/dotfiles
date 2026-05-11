---@type LazySpec
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "AI" },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = {
      nes = {
        enabled = true,
        diff = { inline = "words" },
      },
      cli = {
        -- tmux backend: each CLI tool runs in a detached tmux pane, so
        -- toggling the sidekick window (or restarting nvim) keeps the
        -- claude/codex/etc. session alive.
        mux = { backend = "tmux", enabled = true },
      },
    },
    keys = {
      {
        "<Tab>",
        function()
          -- NES jump/apply when an edit is pending; otherwise fall through so
          -- the literal <Tab> (= <C-i>) still drives jumplist-forward in normal
          -- mode. blink.cmp owns <Tab> in insert mode, so this only binds n.
          if not require("sidekick").nes_jump_or_apply() then return "<Tab>" end
        end,
        expr = true,
        desc = "Sidekick: jump/apply next edit",
      },
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle({ focus = true }) end,
        mode = { "n", "v" },
        desc = "Sidekick: toggle CLI",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        desc = "Sidekick: select CLI",
      },
      {
        "<leader>av",
        function() require("sidekick.cli").send({ selection = true }) end,
        mode = "v",
        desc = "Sidekick: send selection",
      },
      {
        "<leader>af",
        function() require("sidekick.cli").send({ buf = true }) end,
        desc = "Sidekick: send buffer",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "v" },
        desc = "Sidekick: prompt picker",
      },
      {
        "<leader>ac",
        function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
        desc = "Sidekick: Claude",
      },
      {
        "<leader>ao",
        function() require("sidekick.cli").toggle({ name = "codex", focus = true }) end,
        desc = "Sidekick: Codex",
      },
      {
        "<leader>ag",
        function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end,
        desc = "Sidekick: Gemini",
      },
      {
        "<leader>an",
        function()
          vim.g.sidekick_nes = vim.g.sidekick_nes == false and nil or false
          if vim.g.sidekick_nes == false then require("sidekick").clear() end
          vim.notify("Sidekick NES: " .. (vim.g.sidekick_nes == false and "off" or "on"))
        end,
        desc = "Sidekick: toggle NES",
      },
      {
        "<C-.>",
        function() require("sidekick.cli").focus() end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick: focus CLI",
      },
    },
  },
}
