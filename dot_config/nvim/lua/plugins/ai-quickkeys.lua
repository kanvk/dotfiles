-- Additive layer on top of `astrocommunity.ai.sidekick-nvim`, which uses
-- `<Leader>A*` (capital A) per AstroNvim's sub-namespace convention. These
-- map the three CLIs I actually reach for and a "send current line" shortcut.

-- sidekick.cli.close() only detaches the nvim end — when mux is enabled, the
-- tmux/zellij session keeps the CLI process alive. The x/X kill bindings below
-- enumerate sessions through sidekick's own registry (never tmux ls), so they
-- can't touch sessions sidekick didn't spawn.
local function label(s)
  return ("%-8s %s  [%s]"):format(s.tool.name, vim.fn.fnamemodify(s.cwd, ":~"), s.backend)
end

-- session.id is sidekick's internal pane id ("tmux <pid>"). The actual mux
-- session name is session.mux_session — that's what tmux/zellij addresses.
local function kill_one(session)
  local cmd
  if session.backend == "tmux" then
    cmd = { "tmux", "kill-session", "-t", session.mux_session }
  elseif session.backend == "zellij" then
    cmd = { "zellij", "delete-session", "--force", session.mux_session }
  else
    vim.notify("Sidekick: no killer for backend " .. tostring(session.backend), vim.log.levels.WARN)
    return false
  end
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 then
    local detail = (res.stderr ~= "" and res.stderr or res.stdout or ""):gsub("%s+$", "")
    vim.notify(("Sidekick: `%s` exited %d%s"):format(
      table.concat(cmd, " "), res.code, detail ~= "" and "\n" .. detail or ""),
      vim.log.levels.ERROR)
    return false
  end
  return true
end

local function kill_all()
  local list = require("sidekick.cli.session").sessions()
  if #list == 0 then vim.notify("No sidekick sessions running") return end
  local prompt = ("Kill all %d sidekick session(s)?\n  %s"):format(#list,
    table.concat(vim.tbl_map(label, list), "\n  "))
  if vim.fn.confirm(prompt, "&Yes\n&No", 2, "Warning") ~= 1 then return end
  local killed = 0
  for _, s in ipairs(list) do if kill_one(s) then killed = killed + 1 end end
  vim.notify(("Killed %d/%d sidekick session(s)"):format(killed, #list))
end

local function kill_pick()
  local list = require("sidekick.cli.session").sessions()
  if #list == 0 then vim.notify("No sidekick sessions running") return end
  vim.ui.select(list, { prompt = "Kill sidekick session:", format_item = label }, function(pick)
    if not pick then return end
    if kill_one(pick) then vim.notify("Killed " .. label(pick)) end
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
