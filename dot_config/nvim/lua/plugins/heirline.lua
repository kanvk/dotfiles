return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require "astroui.status"
    local right_sep = "\xee\x82\xb2" -- powerline left separator (U+E0B2)
    local right_update = { "ModeChanged", pattern = "*:*" }
    local width = {
      position = 45,
      virtual_env = 65,
      time = 80,
      user_host = 100,
    }

    local function normalize_color(color)
      if type(color) == "number" then return string.format("#%06x", color) end
      return color
    end

    local function loaded_color(name)
      local colors = require("heirline.highlights").get_loaded_colors()
      return normalize_color(colors[name] or name)
    end

    local function hl_color(group, attr, fallback)
      return normalize_color(require("astroui").get_hlgroup(group)[attr]) or fallback
    end

    local function lualine_section(section, attr, fallback)
      local ok, theme = pcall(require, "lualine.themes." .. (vim.g.colors_name or ""))
      local mode = status.hl.mode_bg()
      local mode_section = ok and theme[mode] and theme[mode][section]
      local normal_section = ok and theme.normal and theme.normal[section]
      return normalize_color(
        (mode_section and mode_section[attr]) or (normal_section and normal_section[attr]) or fallback
      )
    end

    local function line_bg()
      return lualine_section("b", "bg", hl_color("Normal", "bg", loaded_color "bg"))
    end

    local function mode_fg()
      return { fg = lualine_section("b", "fg", status.hl.mode_bg()) }
    end

    local function clock_bg()
      return lualine_section("a", "bg", status.hl.mode_bg())
    end

    local function clock_fg()
      return { fg = lualine_section("a", "fg", "mode_fg") }
    end

    local function min_width(name)
      return status.utils.width() >= width[name]
    end

    local function short_host(host)
      host = host:gsub("%..*$", "")
      return #host > 10 and host:sub(1, 9) .. "~" or host
    end

    local function right_block(main, left, condition)
      return {
        separator = { right_sep, "" },
        color = function()
          return {
            main = type(main) == "function" and main() or main or status.hl.mode_bg(),
            left = type(left) == "function" and left() or left or "bg",
          }
        end,
        condition = condition,
        update = right_update,
      }
    end

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
      status.component.virtual_env {
        surround = {
          separator = "right",
          color = "virtual_env_bg",
          condition = function()
            return min_width "virtual_env" and status.condition.has_virtual_env()
          end,
        },
      },
      -- Right-side order: user@host, percentage + row:col, clock.
      status.component.builder {
        condition = function() return min_width "user_host" end,
        init = function(self)
          self.user = os.getenv "USER" or "user"
          self.host = vim.uv.os_gethostname() or "host"
          self.short_host = short_host(self.host)
        end,
        {
          flexible = 1,
          {
            provider = function(self) return string.format(" %s@%s ", self.user, self.host) end,
          },
          {
            provider = function(self) return string.format(" %s@%s ", self.user, self.short_host) end,
          },
          { provider = "" },
        },
        hl = { fg = "fg", bg = "bg" },
        update = { "VimResized", "WinResized" },
      },
      status.component.builder {
        {
          provider = status.provider.percentage {
            padding = { left = 1 },
          },
        },
        {
          provider = status.provider.ruler {
            pad_ruler = { line = 3, char = 1 },
            padding = { left = 1, right = 1 },
          },
        },
        condition = function() return min_width "position" end,
        hl = mode_fg,
        surround = right_block(line_bg, nil, function() return min_width "position" end),
        update = {
          "CursorMoved",
          "CursorMovedI",
          "BufEnter",
          "ModeChanged",
          "VimResized",
          "WinResized",
        },
      },
      -- Create a custom component to display the time
      status.component.builder {
        {
          provider = function()
            local time = os.date "%-I:%M %p" -- 12-hour clock, no leading zero
            ---@cast time string
            return status.utils.stylize(time, {
              padding = { left = 1, right = 1 },
            })
          end,
        },
        condition = function() return min_width "time" end,
        update = { -- update should happen when the mode has changed as well as when the time has changed
          "User", -- We can use the User autocmd event space to tell the component when to update
          "ModeChanged",
          "VimResized",
          "WinResized",
          callback = vim.schedule_wrap(function(_, args)
            if -- update on user UpdateTime event and mode change
              (args.event == "User" and args.match == "UpdateTime")
              or (args.event == "ModeChanged" and args.match:match ".*:.*")
              or args.event == "VimResized"
              or args.event == "WinResized"
            then
              vim.cmd.redrawstatus() -- redraw on update
            end
          end),
        },
        hl = clock_fg,
        surround = right_block(clock_bg, line_bg, function() return min_width "time" end),
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
