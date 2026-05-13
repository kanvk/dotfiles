-- You can also add or configure plugins by creating files in this `plugins/` folder

---@type LazySpec
return {
  -- Added plugins
  {
    "metakirby5/codi.vim",
    lazy = true,
    cmd = "Codi",
  },

  -- Companion to nvim-spider from the same author: adds ~30 textobjects
  -- (iS/aS subword, iv/av value, ii/aI indentation, iU url, ...) on top of
  -- vim's built-ins.
  --
  -- Disable the 5 default LHS that collide with valuable preexisting maps and
  -- rebind the displaced textobjs to free alternates:
  --   ak/ik (block, treesitter)    -> aK/iK   for `key`
  --   ao/io (loop,  treesitter)    -> aO/iO   for `anyBracket`
  --   r     (flash treesitter)     -> gr      for `restOfParagraph`
  --   R     (flash remote)         -> gR      for `restOfIndentation`
  --   an/in (vim built-in argument)-> --      `number` left unbound; dial.nvim
  --                                   (already loaded via astrocommunity)
  --                                   covers the `<C-a>`/`<C-x>` increment use
  --                                   case the README cites as the motivation.
  {
    "chrisgrieser/nvim-various-textobjs",
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
        disabledDefaults = { "ak", "ik", "ao", "io", "an", "in", "r", "R" },
      },
    },
    keys = {
      { "aK", "<cmd>lua require('various-textobjs').key('outer')<cr>",        mode = { "o", "x" }, desc = "outer key textobj" },
      { "iK", "<cmd>lua require('various-textobjs').key('inner')<cr>",        mode = { "o", "x" }, desc = "inner key textobj" },
      { "aO", "<cmd>lua require('various-textobjs').anyBracket('outer')<cr>", mode = { "o", "x" }, desc = "outer any-bracket textobj" },
      { "iO", "<cmd>lua require('various-textobjs').anyBracket('inner')<cr>", mode = { "o", "x" }, desc = "inner any-bracket textobj" },
      { "gr", "<cmd>lua require('various-textobjs').restOfParagraph()<cr>",   mode = { "o", "x" }, desc = "rest of paragraph" },
      { "gR", "<cmd>lua require('various-textobjs').restOfIndentation()<cr>", mode = { "o", "x" }, desc = "rest of indentation" },
    },
  },

  -- Lets `.` repeat plugin-defined operations (surround, etc.) in addition
  -- to vim's built-in changes. No-op until a plugin that calls
  -- `repeat#set()` is installed; tiny enough to keep loaded eagerly.
  { "tpope/vim-repeat", lazy = false },
  -- ys{motion}{char} adds, cs{old}{new} changes, ds{char} deletes surrounds.
  -- Pairs with vim-repeat so `.` re-applies the last surround edit.
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
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

  -- luarocks.nvim's bootstrap installs the luarocks CLI but never deposits
  -- `dkjson.lua` as a top-level module on Lua's package.path. On first start
  -- `require("luarocks.loader")` -> `luarocks.core.persist` -> `require("dkjson")`
  -- then fails, even though the CLI itself works (it sets LUA_PATH to find the
  -- vendored copy). Add `dkjson` to the rocks list so the bootstrap installs
  -- it the same way it installs luautf8. AstroCommunity's nvim-spider spec
  -- requests `{"luautf8"}`; use the function form to append rather than
  -- replace.
  {
    "vhyrro/luarocks.nvim",
    opts = function(_, opts)
      opts.rocks = opts.rocks or {}
      if not vim.tbl_contains(opts.rocks, "dkjson") then table.insert(opts.rocks, "dkjson") end
      return opts
    end,
  },

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

      -- Projects picker (<Leader>fp, dashboard `p`): point at ~/p as the
      -- canonical dev root. Defaults are ~/dev + ~/projects, neither of
      -- which exist on this user's machines.
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.projects = vim.tbl_deep_extend("force", opts.picker.sources.projects or {}, {
        dev = { "~/p" },
      })

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
        { key = "s", icon = "󰋚", desc = "Last Session  ", action = function() require("persistence").load { last = true } end },
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
