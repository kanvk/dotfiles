---@type LazySpec
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
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
      },
      completion = {
        menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end },
        ghost_text = { enabled = false },
        list = { selection = { preselect = false, auto_insert = true } },
      },
    })

    opts.appearance = vim.tbl_deep_extend("force", opts.appearance or {}, { nerd_font_variant = "mono" })
  end,
}
