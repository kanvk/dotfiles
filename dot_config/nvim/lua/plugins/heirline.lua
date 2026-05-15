return {
  "rebelot/heirline.nvim",
  dependencies = {
    { -- configure AstroUI to include a new UI icon
      "AstroNvim/astroui",
      ---@type AstroUIOpts
      opts = {
        icons = {
          Clock = "\xee\x8e\x81", -- add icon for clock (nerd font U+E381)
        },
      },
    },
  },
  opts = function(_, opts)
    local status = require "astroui.status"
    opts.statusline = { -- statusline
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
      -- Right-side order: user@host, percentage (Top/Bot/N%), row:col, clock.
      status.component.builder {
        provider = function()
          local user = os.getenv "USER" or "user"
          local host = vim.uv.os_gethostname() or "host"
          return string.format(" %s@%s ", user, host)
        end,
        hl = { fg = "fg", bg = "bg" },
      },
      {
        provider = status.provider.percentage(),
        update = { "CursorMoved", "CursorMovedI", "BufEnter" },
      },
      {
        provider = status.provider.ruler { padding = { left = 1 } },
        update = { "CursorMoved", "CursorMovedI", "BufEnter" },
      },
      -- Create a custom component to display the time
      status.component.builder {
        {
          provider = function()
            local time = os.date "%-I:%M %p" -- 12-hour clock, no leading zero
            ---@cast time string
            return status.utils.stylize(time, {
              icon = { kind = "Clock", padding = { left = 1, right = 1 } }, -- use our new clock icon
              padding = { right = 1 }, -- pad the right side so it's not cramped
            })
          end,
        },
        update = { -- update should happen when the mode has changed as well as when the time has changed
          "User", -- We can use the User autocmd event space to tell the component when to update
          "ModeChanged",
          callback = vim.schedule_wrap(function(_, args)
            if -- update on user UpdateTime event and mode change
              (args.event == "User" and args.match == "UpdateTime")
              or (args.event == "ModeChanged" and args.match:match ".*:.*")
            then
              vim.cmd.redrawstatus() -- redraw on update
            end
          end),
        },
      },
    }

    -- Now that we have the component, we need a timer to emit the User UpdateTime event.
    -- Stash on _G so a :Lazy reload doesn't leak the prior handle.
    if _G.__heirline_clock_timer then _G.__heirline_clock_timer:close() end
    _G.__heirline_clock_timer = vim.uv.new_timer()
    _G.__heirline_clock_timer:start( -- timer for updating the time
      (60 - tonumber(os.date "%S")) * 1000, -- offset timer based on current seconds past the minute
      60000, -- update every 60 seconds
      vim.schedule_wrap(function()
        vim.api.nvim_exec_autocmds( -- emit our new User event
          "User",
          { pattern = "UpdateTime", modeline = false }
        )
      end)
    )

    -- Close the libuv timer on Vim exit so its handle doesn't survive the editor.
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("HeirlineClockTimerCleanup", { clear = true }),
      callback = function()
        if _G.__heirline_clock_timer then
          _G.__heirline_clock_timer:close()
          _G.__heirline_clock_timer = nil
        end
      end,
    })
  end,
}
