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
