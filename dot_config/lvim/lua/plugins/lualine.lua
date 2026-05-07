---@type LazySpec
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local function user_host()
      return string.format(" %s@%s", os.getenv "USER" or "user", vim.uv.os_gethostname() or "host")
    end

    local function clock()
      return os.date "%H:%M"
    end

    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    table.insert(opts.sections.lualine_x, { user_host })
    table.insert(opts.sections.lualine_x, { clock, icon = "" })

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
