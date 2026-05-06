-- LazyVim parity overrides for blink.cmp.
-- Switches AstroNvim core's hand-rolled keymap to the upstream-recommended
-- "enter" preset + targeted overrides, opts into auto-popup on `:` cmdline,
-- and aligns nerd-font icon spacing.

---@type LazySpec
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    -- Replace the core keymap wholesale (deep-merging the preset with the
    -- existing per-key tables creates conflicts; cleaner to overwrite).
    -- The Tab/S-Tab chain cycles the menu when visible, jumps placeholders
    -- inside an active snippet, and falls through to a literal Tab otherwise.
    opts.keymap = {
      preset = "enter",
      ["<C-y>"] = { "select_and_accept" },
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      -- AstroNvim niceties — keep these so the rest of the muscle memory
      -- carries over verbatim.
      ["<C-J>"] = { "select_next", "fallback" },
      ["<C-K>"] = { "select_prev", "fallback" },
      ["<C-U>"] = { "scroll_documentation_up", "fallback" },
      ["<C-D>"] = { "scroll_documentation_down", "fallback" },
    }

    -- AstroNvim core uses a single `auto_show` predicate that gates on
    -- `ctx.mode ~= "cmdline"`, suppressing the popup for every cmdline
    -- flavor. LazyVim splits this: top-level always-on, cmdline-specific
    -- predicate that fires only on `:`. Match LazyVim — `:e ` pops a file
    -- picker; `/foo` stays quiet.
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
