-- You can also add or configure plugins by creating files in this `plugins/` folder

---@type LazySpec
return {
  -- Added plugins
  {
    "metakirby5/codi.vim",
    lazy = true,
    cmd = "Codi",
  },

  -- w/e/b/ge stay vim-native (subword granularity gets in the way of moving
  -- across whole identifiers/funcs). Spider's subword motions are exposed on
  -- <Leader>s* for the occasional finer jump. Group desc registered in
  -- plugins/astrocore.lua.
  --
  -- luarocks.nvim dep mirrors what AstroCommunity's pack does: installs
  -- luautf8 (spider uses it via pcall(require, "lua-utf8") for UTF-8 word
  -- boundaries) and dkjson (which luarocks.nvim's own loader requires on
  -- cold start — see the notes there). luajit on PATH at apply-time satisfies
  -- the bootstrap (.chezmoidata.yaml base tier).
  {
    "chrisgrieser/nvim-spider",
    dependencies = {
      {
        "vhyrro/luarocks.nvim",
        priority = 1000,
        opts = { rocks = { "luautf8", "dkjson" } },
      },
    },
    keys = {
      { "<Leader>sw",  "<cmd>lua require('spider').motion('w')<cr>",  mode = { "n", "x", "o" }, desc = "Next subword" },
      { "<Leader>se",  "<cmd>lua require('spider').motion('e')<cr>",  mode = { "n", "x", "o" }, desc = "Next end of subword" },
      { "<Leader>sb",  "<cmd>lua require('spider').motion('b')<cr>",  mode = { "n", "x", "o" }, desc = "Previous subword" },
      { "<Leader>sE",  "<cmd>lua require('spider').motion('ge')<cr>", mode = { "n", "x", "o" }, desc = "Previous end of subword" },
    },
    opts = {},
  },

  -- Function-form astrocore spec that runs last (user plugins after
  -- community packs), reclaiming LHS that earlier function-form opts have
  -- set. Fixes <Leader>-prefix timeout collisions where a shorter LHS was a
  -- complete mapping AND a prefix of longer ones (timeoutlen=500ms felt on
  -- every press of the short form). Where possible, mirrors lvim conventions.
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.x = opts.mappings.x or {}
      opts.mappings.v = opts.mappings.v or {}

      -- Spectre + spider rewires (from prior session).
      --   n.<Leader>ss disabled; spectre's main open at <Leader>sR (matches lvim).
      --   x.<Leader>sw -> spider's "next subword"; spectre's visual current-word
      --     moved to <Leader>sW in plugins/astrocore.lua.
      opts.mappings.n["<Leader>ss"] = false
      opts.mappings.n["<Leader>sR"] = {
        function() require("spectre").open() end,
        desc = "Spectre (project search-replace)",
      }
      opts.mappings.x["<Leader>sw"] = {
        "<Cmd>lua require('spider').motion('w')<CR>",
        desc = "Next subword",
      }

      -- <Leader>c/<Leader>C (Close / Force close buffer) move to
      -- <Leader>bd/<Leader>bD (LazyVim style). The <Leader>c namespace is
      -- now fully empty — code/LSP actions live under <Leader>l* (where
      -- AstroNvim already has la/lA/lr/lR/lh/lf/ll/lL/lG/ls/lS/ld/lD/lw),
      -- and file-rename moved to <Leader>fR.
      opts.mappings.n["<Leader>c"] = false
      opts.mappings.n["<Leader>C"] = false
      opts.mappings.n["<Leader>bd"] = {
        function() require("astrocore.buffer").close() end,
        desc = "Close buffer",
      }
      opts.mappings.n["<Leader>bD"] = {
        function() require("astrocore.buffer").close(0, true) end,
        desc = "Force close buffer",
      }
      -- AstroNvim's heirline binds <Leader>bd to a tabline-picker close;
      -- <Leader>bp is taken by "Previous buffer", so relocate the picker to
      -- <Leader>bx (b-X-out via picker).
      opts.mappings.n["<Leader>bx"] = {
        function()
          require("astroui.status.heirline").buffer_picker(function(bufnr) require("astrocore.buffer").close(bufnr) end)
        end,
        desc = "Close buffer (pick from tabline)",
      }

      -- <Leader>q (Quit Window) collides with persistence.lua's q* session
      -- bindings. Move quit-window to <Leader>qq (LazyVim style);
      -- <Leader>q becomes a "Quit / Session" group prefix. <Leader>Q
      -- (Exit AstroNvim = qall) moves to <Leader>qQ for parallel treatment
      -- with <Leader>C -> <Leader>bD.
      opts.mappings.n["<Leader>q"] = { desc = "Quit / Session" }
      opts.mappings.n["<Leader>qq"] = { "<Cmd>confirm q<CR>", desc = "Quit Window" }
      opts.mappings.n["<Leader>Q"] = false
      opts.mappings.n["<Leader>qQ"] = { "<Cmd>confirm qall<CR>", desc = "Exit AstroNvim" }

      -- <Leader>rb (Extract Function) collides with <Leader>rbf (Extract
      -- Function To File) — both from astrocommunity refactoring-nvim.
      -- Move the longer to <Leader>rF (matches lvim's refactoring extra).
      local extract_to_file = function() require("refactoring").refactor("Extract Function To File") end
      opts.mappings.n["<Leader>rbf"] = false
      opts.mappings.n["<Leader>rF"] = { extract_to_file, desc = "Extract Function To File" }
      opts.mappings.v["<Leader>rbf"] = false
      opts.mappings.v["<Leader>rF"] = { extract_to_file, desc = "Extract Function To File" }
    end,
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
