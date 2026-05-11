-- Additive layer on top of `astrocommunity.ai.sidekick-nvim`, which uses
-- `<Leader>A*` (capital A) per AstroNvim's sub-namespace convention. These
-- map the three CLIs I actually reach for and a "send current line" shortcut.

-- sidekick.cli.close() only detaches the nvim end — when mux is enabled, the
-- tmux/zellij session keeps the CLI process alive. The x/X kill bindings below
-- enumerate sessions through sidekick's own registry (never tmux ls), so they
-- can't touch sessions sidekick didn't spawn.
local function kill_one(session)
  if session.backend == "tmux" then
    vim.fn.system({ "tmux", "kill-session", "-t", session.id })
  elseif session.backend == "zellij" then
    vim.fn.system({ "zellij", "delete-session", "--force", session.id })
  else
    vim.notify("Sidekick: no killer for backend " .. tostring(session.backend), vim.log.levels.WARN)
  end
end

local function kill_all()
  local list = require("sidekick.cli.session").sessions()
  if #list == 0 then vim.notify("No sidekick sessions running") return end
  for _, s in ipairs(list) do kill_one(s) end
  vim.notify(("Killed %d sidekick session(s)"):format(#list))
end

local function kill_pick()
  local list = require("sidekick.cli.session").sessions()
  if #list == 0 then vim.notify("No sidekick sessions running") return end
  vim.ui.select(list, {
    prompt = "Kill sidekick session:",
    format_item = function(s) return ("%s  [%s]"):format(s.id, s.backend) end,
  }, function(pick)
    if not pick then return end
    kill_one(pick)
    vim.notify("Killed " .. pick.id)
  end)
end

---@type LazySpec
return {
  {
    "folke/sidekick.nvim",
    keys = {
      { "<Leader>Ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Sidekick: Claude" },
      { "<Leader>Ao", function() require("sidekick.cli").toggle({ name = "codex",  focus = true }) end, desc = "Sidekick: Codex" },
      { "<Leader>Ag", function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end, desc = "Sidekick: Gemini" },
      { "<Leader>Al", function() require("sidekick.cli").send({ msg = "{line}" }) end, desc = "Sidekick: send current line" },
      { "<Leader>Ax", kill_pick, desc = "Sidekick: kill session (pick)" },
      { "<Leader>AX", kill_all,  desc = "Sidekick: kill all sessions" },
    },
  },
}
