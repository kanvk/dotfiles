---@type LazySpec
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    -- Tab/S-Tab cycle the menu when visible, jump snippet placeholders
    -- inside an active snippet, then fall through to a literal Tab.
    opts.keymap = {
      preset = "enter",
      ["<C-y>"] = { "select_and_accept" },
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<C-J>"] = { "select_next", "fallback" },
      ["<C-K>"] = { "select_prev", "fallback" },
      ["<C-U>"] = { "scroll_documentation_up", "fallback" },
      ["<C-D>"] = { "scroll_documentation_down", "fallback" },
    }

    -- Auto-popup the menu on `:` Ex commands; stay quiet on `/` and `?` searches.
    opts.completion = opts.completion or {}
    opts.completion.menu = opts.completion.menu or {}
    opts.completion.menu.auto_show = true

    -- Cmdline keymap: nothing is preselected when the menu opens (so an
    -- absent-minded Enter still runs the typed text rather than silently
    -- swapping in the first suggestion), but Tab/arrows do auto-insert the
    -- currently selected item — that's what makes `Co<Tab>` expand to
    -- `Copilot` so you can continue typing ` auth`. <CR> accepts whatever's
    -- selected and runs; with nothing selected it falls back to Vim's
    -- normal behavior of executing the typed text.
    opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
      keymap = {
        preset = "cmdline",
        ["<CR>"] = { "accept_and_enter", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        -- blink.cmp's "cmdline" preset binds Left/Right to select_prev/_next,
        -- which hijacks vim's cursor movement through the typed cmdline text.
        -- Setting them to `{ "fallback" }` does NOT work: blink's
        -- keymap/init.lua get_mappings() filters out user overrides that lack
        -- a non-fallback insert command BEFORE merging the preset, so the
        -- preset's Left/Right survives. Setting to `false` instead survives
        -- the filter and is removed in a later step, so blink registers no
        -- cmap at all and vim's native cmdline cursor movement takes over.
        -- (Up/Down + Tab/S-Tab still drive the menu.)
        ["<Left>"] = false,
        ["<Right>"] = false,
      },
      completion = {
        menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end },
        ghost_text = { enabled = false },
        list = { selection = { preselect = false, auto_insert = true } },
      },
    })

    opts.appearance = opts.appearance or {}
    opts.appearance.nerd_font_variant = "mono"
  end,
}
