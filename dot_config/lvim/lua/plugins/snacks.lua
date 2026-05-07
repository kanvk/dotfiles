---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.bigfile = { enabled = true, size = 10 * 1024 * 1024 }
    opts.gh = { enabled = true }

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.preset = opts.dashboard.preset or {}

    opts.dashboard.preset.header = table.concat({
      "     ██╗  ██╗ █████╗ ███╗   ██╗██╗   ██╗██╗  ██╗",
      "     ██║ ██╔╝██╔══██╗████╗  ██║██║   ██║██║ ██╔╝",
      "     █████╔╝ ███████║██╔██╗ ██║██║   ██║█████╔╝",
      "     ██╔═██╗ ██╔══██║██║╚██╗██║╚██╗ ██╔╝██╔═██╗",
      "     ██║  ██╗██║  ██║██║ ╚████║ ╚████╔╝ ██║  ██╗",
      "     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝  ╚═╝",
    }, "\n")

    opts.dashboard.preset.keys = {
      { key = "s", icon = "󰋚", desc = "Last Session  ",
        action = function() require("persistence").load { last = true } end },
      { key = "p", icon = "󰉋", desc = "Projects  ",
        action = function() Snacks.picker.projects() end },
      { key = "o", icon = "󰈚", desc = "Recents  ",
        action = function() Snacks.picker.recent() end },
      { key = "'", icon = "󰃃", desc = "Bookmarks  ",
        action = function() Snacks.picker.marks() end },
      { key = "f", icon = "󰈞", desc = "Find File  ",
        action = function() Snacks.picker.files() end },
      { key = "z", icon = "󰓅", desc = "Zoxide  ",
        action = function() Snacks.picker.zoxide() end },
      { key = "g", icon = "󰊢", desc = "Git Status  ",
        action = function() Snacks.picker.git_status() end },
      { key = "w", icon = "󰈭", desc = "Find Word  ",
        action = function() Snacks.picker.grep() end },
      { key = "n", icon = "󰈔", desc = "New File  ", action = ":enew" },
      { key = ",", icon = "󰎚", desc = "Scratch  ",
        action = function() Snacks.scratch() end },
      { key = "r", icon = "󰐊", desc = "Run Task  ", action = ":OverseerRun" },
      { key = "T", icon = "󰗇", desc = "Test Summary  ",
        action = function() require("neotest").summary.toggle() end },
      { key = "k", icon = "󰌌", desc = "Keymaps  ",
        action = function() Snacks.picker.keymaps() end },
    }
  end,
}
