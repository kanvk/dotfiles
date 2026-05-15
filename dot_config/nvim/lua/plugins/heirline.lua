return {
  "rebelot/heirline.nvim",
  dependencies = {
    {
      "AstroNvim/astroui",
      ---@type AstroUIOpts
      opts = {
        icons = {
          Clock = "",
        },
      },
    },
  },
  opts = function(_, opts)
    local status = require "astroui.status"
    opts.statusline = {
      hl = { fg = "fg", bg = "bg" },
      status.component.mode(),
      status.component.git_branch(),
      status.component.file_info(),
      status.component.git_diff(),
      status.component.diagnostics(),
      status.component.fill(),
      status.component.cmd_info(),
      status.component.fill(),
      status.component.lsp(),
      status.component.virtual_env(),
      status.component.treesitter(),
      -- Colored nav block (top % + position) with a `<`-shaped powerline
      -- surround. Same visual treatment as lualine_y in lvim.
      status.component.nav {
        surround = { separator = "left", color = "git_branch_bg" },
      },
      status.component.builder {
        provider = function()
          local user = os.getenv "USER" or "user"
          local host = vim.uv.os_gethostname() or "host"
          return string.format(" %s@%s", user, host)
        end,
        hl = { fg = "fg", bg = "bg" },
      },
      -- 12h clock, mode-tied highlight, `<` powerline surround.
      -- Same visual treatment as lualine_z in lvim.
      status.component.builder {
        {
          provider = function()
            local time = os.date "%-I:%M %p"
            ---@cast time string
            return status.utils.stylize(time, {
              icon = { kind = "Clock", padding = { left = 1, right = 1 } },
              padding = { right = 1 },
            })
          end,
        },
        update = {
          "User",
          "ModeChanged",
          callback = vim.schedule_wrap(function(_, args)
            if
              (args.event == "User" and args.match == "UpdateTime")
              or (args.event == "ModeChanged" and args.match:match ".*:.*")
            then
              vim.cmd.redrawstatus()
            end
          end),
        },
        hl = status.hl.get_attributes "mode",
        surround = { separator = "left", color = status.hl.mode_bg },
      },
    }

    -- Stash the timer handle on _G so a :Lazy reload doesn't leak the prior one.
    if _G.__heirline_clock_timer then _G.__heirline_clock_timer:close() end
    _G.__heirline_clock_timer = vim.uv.new_timer()
    _G.__heirline_clock_timer:start(
      (60 - tonumber(os.date "%S")) * 1000,
      60000,
      vim.schedule_wrap(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "UpdateTime", modeline = false })
      end)
    )
  end,
}
