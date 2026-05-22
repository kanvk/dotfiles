local map = vim.keymap.set

map("n", "]T", function() require("todo-comments").jump_next() end, { desc = "Next TODO comment" })
map("n", "[T", function() require("todo-comments").jump_prev() end, { desc = "Previous TODO comment" })
map("n", "]n", function() require("neotest").jump.next() end, { desc = "Next test" })
map("n", "[n", function() require("neotest").jump.prev() end, { desc = "Previous test" })

-- LazyVim hardcodes <leader>gl (project-rooted log picker) in
-- lazyvim/config/keymaps.lua, which runs after lazy spec processing and would
-- shadow a lazy `keys` entry. Re-bind here so DiffviewFileHistory wins.
-- <leader>gL stays at LazyVim's default (cwd-rooted Snacks log picker).
map("n", "<Leader>gl", "<cmd>DiffviewFileHistory<cr>", { desc = "File history (repo-wide)" })

map("n", "<Leader>ul", function() vim.opt.list = not vim.opt.list:get() end, { desc = "Toggle listchars (show hidden)" })

-- LazyVim's vanilla <C-Arrow> :resize bindings (lazyvim/config/keymaps.lua)
-- are unbound so smart-splits' <C-S-Arrow> is the single resize chord and
-- <C-Arrow> stays free at every layer for zsh word motion. LazyVim's
-- config/keymaps.lua runs after lazy spec processing, so a lazy `keys = {}`
-- entry on the smart-splits spec wouldn't have shadowed these; vim.keymap.del
-- here runs after both and wins.
for _, lhs in ipairs { "<C-Up>", "<C-Down>", "<C-Left>", "<C-Right>" } do
  pcall(vim.keymap.del, "n", lhs)
end
