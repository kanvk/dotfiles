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

    opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
      completion = {
        menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end },
        ghost_text = { enabled = true },
      },
    })

    opts.appearance = opts.appearance or {}
    opts.appearance.nerd_font_variant = "mono"
  end,
}
