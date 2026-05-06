-- You can also add or configure plugins by creating files in this `plugins/` folder

---@type LazySpec
return {
  -- Added plugins
  {
    "metakirby5/codi.vim",
    lazy = true,
    cmd = "Codi",
  },

  -- Transparent .ipynb <-> .py(percent) conversion on read/write so molten
  -- can drive Jupyter notebooks via cell markers (`# %%`). Requires the
  -- jupytext CLI (installed via pipx — see .chezmoidata.yaml).
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      style = "percent",
      output_extension = "auto",
      force_ft = nil,
    },
  },

  -- Register neotest-python adapter (pytest by default).
  -- Add neotest-go / neotest-rust / etc. dependencies and adapters here as needed.
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-python")({
          runner = "pytest",
          dap = { justMyCode = false },
        })
      )
    end,
  },

  -- Modified plugins
  {
    "folke/snacks.nvim",
    -- Full dashboard ordering owned by us. Replaces AstroNvim's preset.keys
    -- entirely so the resume-context items rise to the top. Icons are literal
    -- nerd-font Material Design glyphs (U+F02xx–U+F05xx range) chosen for
    -- consistent rendering — the AstroNvim defaults were a mix of narrow
    -- private-use glyphs (FileNew, Search, Bookmarks, Refresh) that didn't
    -- render visibly in CaskaydiaCove alongside the wider DefaultFile/WordFile.
    opts = function(_, opts)
      -- Bumped from snacks' 1.5MB default to 10MB — notebooks and generated
      -- files routinely cross 1.5MB without being painful to edit.
      opts.bigfile = { enabled = true, size = 10 * 1024 * 1024 }

      -- Render the file before plugins/treesitter/LSP attach on cold open
      -- (`nvim somefile.txt`) — pure latency win, no behavior change.
      opts.quickfile = { enabled = true }

      -- GitHub issues + PRs in-buffer via the `gh` CLI. Adds the
      -- `gh_issue` / `gh_pr` picker sources used by the <Leader>gH* maps
      -- in astrocore.lua. Requires `gh auth login`.
      opts.gh = { enabled = true }

      -- Smooth-scroll animation on <C-d>/<C-u>/gg/G/etc. Defaults are
      -- mild (200ms total, linear); tweak in scroll.animate if needed.
      opts.scroll = { enabled = true }

      -- Indent column at every level (`indent`) + animated highlight of the
      -- current indent scope (`scope`). Same combo LazyVim enables by default.
      opts.indent = { enabled = true }
      opts.scope = { enabled = true }

      -- gitbrowse + rename are function-call modules (`Snacks.gitbrowse()`,
      -- `Snacks.rename.rename_file()`); they lazy-load on first invoke and
      -- don't need an opts entry — see the <Leader>gO and <Leader>cR maps
      -- in astrocore.lua.

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
        -- Resume / context-switch
        { key = "s", icon = "󰋚", desc = "Last Session  ", action = "<Leader>Sl" },
        { key = "p", icon = "󰉋", desc = "Projects  ",     action = ":lua Snacks.picker.projects()" },
        { key = "o", icon = "󰈚", desc = "Recents  ",      action = "<Leader>fo" },
        { key = "'", icon = "󰃃", desc = "Bookmarks  ",    action = "<Leader>f'" },
        -- Open / navigate
        { key = "f", icon = "󰈞", desc = "Find File  ",    action = "<Leader>ff" },
        { key = "z", icon = "󰓅", desc = "Zoxide  ",       action = ":lua Snacks.picker.zoxide()" },
        -- Inspect
        { key = "g", icon = "󰊢", desc = "Git Status  ",   action = ":lua Snacks.picker.git_status()" },
        { key = "w", icon = "󰈭", desc = "Find Word  ",    action = "<Leader>fw" },
        -- Create / execute
        { key = "n", icon = "󰈔", desc = "New File  ",     action = "<Leader>n" },
        { key = ",", icon = "󰎚", desc = "Scratch  ",      action = ":lua Snacks.scratch()" },
        { key = "r", icon = "󰐊", desc = "Run Task  ",     action = ":OverseerRun" },
        { key = "T", icon = "󰗇", desc = "Test Summary  ", action = function() require("neotest").summary.toggle() end },
        -- Meta
        { key = "k", icon = "󰌌", desc = "Keymaps  ",      action = ":lua Snacks.picker.keymaps()" },
      }
    end,
  },

  -- -- == Examples of Adding Plugins ==

  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function() require("lsp_signature").setup() end,
  -- },

  -- -- == Examples of Overriding Plugins ==

  -- -- customize dashboard options
  -- {
  --   "folke/snacks.nvim",
  --   opts = {
  --     dashboard = {
  --       preset = {
  --         header = table.concat({
  --           " █████  ███████ ████████ ██████   ██████ ",
  --           "██   ██ ██         ██    ██   ██ ██    ██",
  --           "███████ ███████    ██    ██████  ██    ██",
  --           "██   ██      ██    ██    ██   ██ ██    ██",
  --           "██   ██ ███████    ██    ██   ██  ██████ ",
  --           "",
  --           "███    ██ ██    ██ ██ ███    ███",
  --           "████   ██ ██    ██ ██ ████  ████",
  --           "██ ██  ██ ██    ██ ██ ██ ████ ██",
  --           "██  ██ ██  ██  ██  ██ ██  ██  ██",
  --           "██   ████   ████   ██ ██      ██",
  --         }, "\n"),
  --       },
  --     },
  --   },
  -- },

  -- -- You can disable default plugins as follows:
  -- { "max397574/better-escape.nvim", enabled = false },

  -- -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  -- {
  --   "L3MON4D3/LuaSnip",
  --   config = function(plugin, opts)
  --     require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
  --     -- add more custom luasnip configuration such as filetype extend or custom snippets
  --     local luasnip = require "luasnip"
  --     luasnip.filetype_extend("javascript", { "javascriptreact" })
  --   end,
  -- },

  -- {
  --   "windwp/nvim-autopairs",
  --   config = function(plugin, opts)
  --     require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
  --     -- add more custom autopairs configuration such as custom rules
  --     local npairs = require "nvim-autopairs"
  --     local Rule = require "nvim-autopairs.rule"
  --     local cond = require "nvim-autopairs.conds"
  --     npairs.add_rules(
  --       {
  --         Rule("$", "$", { "tex", "latex" })
  --           -- don't add a pair if the next character is %
  --           :with_pair(cond.not_after_regex "%%")
  --           -- don't add a pair if  the previous character is xxx
  --           :with_pair(
  --             cond.not_before_regex("xxx", 3)
  --           )
  --           -- don't move right when repeat character
  --           :with_move(cond.none())
  --           -- don't delete if the next character is xx
  --           :with_del(cond.not_after_regex "xx")
  --           -- disable adding a newline when you press <cr>
  --           :with_cr(cond.none()),
  --       },
  --       -- disable for .vim files, but it work for another filetypes
  --       Rule("a", "a", "-vim")
  --     )
  --   end,
  -- },
}
