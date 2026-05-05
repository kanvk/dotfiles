-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    -- filetypes = {
    --   -- see `:h vim.filetype.add` for usage
    --   extension = {
    --     foo = "fooscript",
    --   },
    --   filename = {
    --     [".foorc"] = "fooscript",
    --   },
    --   pattern = {
    --     [".*/etc/foo/.*"] = "fooscript",
    --   },
    -- },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        hidden = true, -- allow hidden buffers
        smartindent = true, -- enable smart indent
        expandtab = true, -- spaces, not tabs
        shiftwidth = 4, -- Set space indent width
        tabstop = 4, -- Set tab indent width
        softtabstop = 4, -- <Tab> inserts shiftwidth spaces
        colorcolumn = "120", -- Set colorcolumn
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false, -- sets vim.opt.wrap
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
        -- Prefer the pipx-managed pynvim venv (per pipx pynvim install in
        -- .chezmoidata.yaml). Fallback to the system python3 if absent.
        python3_host_prog = (function()
          local pipx_py = vim.fn.expand "~/.local/pipx/venvs/pynvim/bin/python"
          return vim.fn.executable(pipx_py) == 1 and pipx_py or vim.fn.exepath "python3"
        end)(),
      },
    },
    -- Custom mappings on top of AstroNvim defaults. AstroNvim already binds
    -- ]b/[b, <Leader>bd, <Leader>fp, <Leader>fk, <Leader>gt, <Leader>s* (spectre)
    -- etc. — only put net-new bindings here.
    mappings = {
      n = {
        -- Snacks scratch — quick scratch buffer + picker over saved scratchpads
        ["<Leader>."] = { function() require("snacks").scratch() end, desc = "Open scratchpad" },
        ["<Leader>fS"] = { function() require("snacks").scratch.select() end, desc = "Find scratchpads" },
        -- Snacks zoxide picker — jump to a frequent dir (mirrors dashboard `z`)
        ["<Leader>fz"] = { function() require("snacks").picker.zoxide() end, desc = "Find via zoxide" },
        -- Zen mode toggle (zen-mode-nvim community pack only registers :ZenMode)
        ["<Leader>uz"] = { "<Cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
      },
    },

    -- AstroNvim v6 template mapping examples (kept for reference).
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    -- mappings = {
    --   -- first key is the mode
    --   n = {
    --     -- second key is the lefthand side of the map
    --
    --     -- navigate buffer tabs
    --     ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
    --     ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
    --
    --     -- mappings seen under group name "Buffer"
    --     ["<Leader>bd"] = {
    --       function()
    --         require("astroui.status.heirline").buffer_picker(
    --           function(bufnr) require("astrocore.buffer").close(bufnr) end
    --         )
    --       end,
    --       desc = "Close buffer from tabline",
    --     },
    --
    --     -- tables with just a `desc` key will be registered with which-key if it's installed
    --     -- this is useful for naming menus
    --     -- ["<Leader>b"] = { desc = "Buffers" },
    --
    --     -- setting a mapping to false will disable it
    --     -- ["<C-S>"] = false,
    --   },
    -- },
  },
}
