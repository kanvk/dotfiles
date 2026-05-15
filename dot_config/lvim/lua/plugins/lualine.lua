---@type LazySpec
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local function user_host()
      return string.format(" %s@%s", os.getenv "USER" or "user", vim.uv.os_gethostname() or "host")
    end

    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    table.insert(opts.sections.lualine_x, { user_host })

    -- LazyVim's lualine_x ships a noice command echo (yy, g…) and a noice
    -- mode indicator (--RECORDING--, search progress). The command one is
    -- tagged with Snacks.util.color("Statement"); mode uses "Constant".
    -- Filter by color match so mode/macro/search status stays visible.
    local statement_fg = require("snacks").util.color "Statement"
    opts.sections.lualine_x = vim.tbl_filter(function(entry)
      if type(entry) ~= "table" or type(entry.color) ~= "function" then return true end
      local ok, c = pcall(entry.color)
      return not (ok and type(c) == "table" and c.fg == statement_fg)
    end, opts.sections.lualine_x)

    -- LazyVim's lualine_z is the canonical clock; override 24h %R -> 12h.
    opts.sections.lualine_z = {
      function() return " " .. os.date "%-I:%M %p" end,
    }

    -- Tick lualine every minute so the z-section clock stays current while
    -- idle (no cursor/mode events to trigger a redraw).
    if _G.__lvim_clock_timer then _G.__lvim_clock_timer:close() end
    _G.__lvim_clock_timer = vim.uv.new_timer()
    _G.__lvim_clock_timer:start(
      (60 - tonumber(os.date "%S")) * 1000,
      60000,
      vim.schedule_wrap(function()
        if pcall(require, "lualine") then require("lualine").refresh() end
      end)
    )
  end,
}
