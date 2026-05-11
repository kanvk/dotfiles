---@type LazySpec
return {
  -- Treesitter-aware `commentstring` for native `gc`/`gcc`. Picks the right
  -- comment syntax for embedded languages (JSX inside TSX, <template> vs
  -- <script> inside Vue/Svelte SFCs, fenced code blocks in Markdown). LazyVim
  -- ships this via its coding extra; AstroNvim doesn't, so wire it here.
  "folke/ts-comments.nvim",
  event = "VeryLazy",
  opts = {},
  enabled = vim.fn.has("nvim-0.10") == 1,
}
