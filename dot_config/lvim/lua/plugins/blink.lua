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
    opts.appearance = vim.tbl_deep_extend("force", opts.appearance or {}, { nerd_font_variant = "mono" })
  end,
}
