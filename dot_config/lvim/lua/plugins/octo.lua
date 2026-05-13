-- GitHub PR/issue review in-buffer via the `gh` CLI. Complements snacks's
-- read-only gh_issue/gh_pr pickers (already on <Leader>gHi/I/p/P in
-- plugins/keymaps.lua) with the write actions (create, comment, review).
--
-- Requires `gh auth login`. Uses snacks as the picker backend (LazyVim's
-- default picker on install_version >= 8). Mirrors the nvim octo spec.

---@type LazySpec
return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-mini/mini.icons" },
  keys = {
    { "<Leader>gHc", "<Cmd>Octo issue create<CR>",  desc = "Issue create" },
    { "<Leader>gHo", "<Cmd>Octo issue search<CR>",  desc = "Issue search" },
    { "<Leader>gHr", "<Cmd>Octo review start<CR>",  desc = "Review (start)" },
    { "<Leader>gHR", "<Cmd>Octo review resume<CR>", desc = "Review (resume)" },
    { "<Leader>gHC", "<Cmd>Octo pr create<CR>",     desc = "PR create" },
  },
  opts = { enable_builtin = true, picker = "snacks" },
}
