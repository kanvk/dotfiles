local map = vim.keymap.set

map("n", "]T", function() require("todo-comments").jump_next() end, { desc = "Next TODO comment" })
map("n", "[T", function() require("todo-comments").jump_prev() end, { desc = "Previous TODO comment" })
map("n", "]n", function() require("neotest").jump.next() end, { desc = "Next test" })
map("n", "[n", function() require("neotest").jump.prev() end, { desc = "Previous test" })
