---@type LazySpec
return {
  -- LazyVim's lang.markdown extra and lspconfig defaults render diagnostics
  -- inline (virtual_text) and in the gutter (signs). Both are visually noisy
  -- — use the on-demand keymaps instead: <leader>cd hovers the line's
  -- diagnostic in a float, ]d / [d / ]e / [e navigate, :Trouble diagnostics
  -- shows the project list. update_in_insert stays off so messages don't
  -- flicker mid-typing.
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        signs = false,
        underline = false,
        update_in_insert = false,
      },
    },
  },
}
