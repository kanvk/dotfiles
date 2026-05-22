return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require "astroui.status"
    local palette = require "statusline_palette"
    local right_sep = "\xee\x82\xb2" -- powerline left separator (U+E0B2)
    local right_update = { "ModeChanged", pattern = "*:*" }
    local width = {
      position = 45,
      virtual_env = 65,
      time = 80,
    }

    local function loaded_color(name)
      local colors = require("heirline.highlights").get_loaded_colors()
      return palette.normalize_color(colors[name] or name)
    end

    local function pick_fg(group, fallback)
      return palette.hl_color(group, "fg",
        palette.lualine_attr(palette.lualine_theme(), "normal", "b", "fg", fallback))
    end

    local function lualine_section(section, attr, fallback)
      return palette.lualine_attr(
        palette.lualine_theme(),
        palette.current_lualine_mode(),
        section,
        attr,
        fallback
      )
    end

    local function line_bg()
      return lualine_section("b", "bg", palette.hl_color("Normal", "bg", loaded_color "bg"))
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

    local function truncate(text, max_width)
      if not max_width or vim.fn.strdisplaywidth(text) <= max_width then return text end
      if max_width <= 1 then return "~" end

      local truncated = ""
      local target_width = max_width - 1
      for char = 1, vim.fn.strchars(text) do
        local next_text = vim.fn.strcharpart(text, 0, char)
        if vim.fn.strdisplaywidth(next_text) > target_width then break end
        truncated = next_text
      end

      return truncated .. "~"
    end

    local function branch_provider(max)
      return function(self)
        local branch = max and truncate(self.branch, max) or self.branch
        return status.utils.stylize(branch, {
          icon = { kind = "GitBranch", padding = { right = 1 } },
        })
      end
    end

    local function option_flags(self)
      local bufnr = self and self.bufnr or 0
      local flags = {}
      if vim.opt.paste:get() then table.insert(flags, "paste") end
      if vim.wo.spell then table.insert(flags, "spell") end
      if vim.wo.wrap then table.insert(flags, "wrap") end
      if vim.bo[bufnr].binary then table.insert(flags, "bin") end

      local fileformat = vim.bo[bufnr].fileformat
      if fileformat == "dos" then
        table.insert(flags, "crlf")
      elseif fileformat == "mac" then
        table.insert(flags, "cr")
      end

      local fileencoding = vim.bo[bufnr].fileencoding
      if fileencoding ~= "" and fileencoding:lower() ~= "utf-8" then
        table.insert(flags, "enc:" .. fileencoding)
      end
      if vim.bo[bufnr].bomb then table.insert(flags, "bom") end
      if not vim.bo[bufnr].endofline then table.insert(flags, "noeol") end
      if not vim.bo[bufnr].fixendofline then table.insert(flags, "nofixeol") end
      return flags
    end

    local function has_option_flags(self)
      return #option_flags(self) > 0
    end

    local function short_host(host)
      host = host:gsub("%..*$", "")
      return truncate(host, 10)
    end

    local function is_ssh_session()
      return vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil
    end

    local function user_host_hl()
      local fg = is_ssh_session() and palette.hl_color("DiagnosticWarn", "fg", loaded_color "yellow")
        or palette.hl_color("Directory", "fg", loaded_color "blue")

      return {
        fg = fg,
        bg = "bg",
        bold = true,
      }
    end

    local function macro_rec_hl()
      return {
        fg = palette.hl_color("WarningMsg", "fg", loaded_color "yellow"),
        bg = "bg",
        bold = true,
      }
    end

    local function git_branch_hl()
      return { fg = pick_fg("GitSignsAdd", loaded_color "green"), bold = true }
    end

    -- NvimEnvironmentName is rarely defined; the chain typically lands at the
    -- lualine theme's normal.b.fg or the heirline "yellow" alias.
    local function virtual_env_hl()
      return { fg = pick_fg("NvimEnvironmentName", loaded_color "yellow"), bold = true }
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
      status.component.builder {
        condition = status.condition.is_git_repo,
        init = function(self)
          status.init.update_events {
            "BufEnter",
            {
              "User",
              pattern = { "GitSignsUpdate", "GitSignsChanged" },
              callback = function() vim.schedule(vim.cmd.redrawstatus) end,
            },
          }(self)
          self.branch = vim.b[self.bufnr or 0].gitsigns_head or ""
        end,
        {
          flexible = 1,
          { provider = branch_provider() },
          { provider = branch_provider(28) },
          { provider = branch_provider(16) },
          { provider = "" },
        },
        surround = {
          separator = "left",
          color = "bg",
          condition = status.condition.is_git_repo,
        },
        on_click = vim.tbl_get(require("astroui").config.status.components, "git_branch", "on_click"),
        hl = git_branch_hl,
      },
      status.component.file_info(),
      status.component.git_diff(),
      status.component.diagnostics(),
      status.component.fill(),
      status.component.cmd_info {
        macro_recording = {
          padding = { left = 1, right = 1 },
          hl = macro_rec_hl,
        },
      },
      status.component.fill(),
      status.component.builder {
        {
          provider = function(self)
            return status.utils.stylize(table.concat(option_flags(self), " "), {
              padding = { left = 1, right = 1 },
            })
          end,
        },
        condition = has_option_flags,
        hl = function() return status.hl.get_attributes "cmd_info" end,
        update = {
          "OptionSet",
          "BufEnter",
          "BufReadPost",
          "BufWritePost",
          "WinEnter",
        },
      },
      status.component.virtual_env {
        surround = {
          separator = "right",
          color = "bg",
          condition = function()
            return min_width "virtual_env" and status.condition.has_virtual_env()
          end,
        },
        hl = virtual_env_hl,
      },
      status.component.builder {
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
        hl = user_host_hl,
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
