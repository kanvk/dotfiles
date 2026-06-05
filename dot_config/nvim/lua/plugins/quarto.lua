-- Quarto (.qmd) literate documents. The community pack (imported in
-- community.lua) supplies quarto-nvim + otter.nvim (embedded LSP inside fenced
-- code blocks) and is ft-gated to quarto/qmd, so nothing here loads until you
-- open a Quarto doc.
--
-- Here we turn on quarto-nvim's code runner against molten-nvim (already
-- imported) so cells execute against a Jupyter kernel with inline output, then
-- bind the upstream <localleader>r* runner keys buffer-locally. Workflow:
-- `:MoltenInit` to start a kernel, then ,rc / ,ra / ,rA / ,rl to run cells.

---@type LazySpec
return {
  "quarto-dev/quarto-nvim",
  opts = {
    codeRunner = {
      enabled = true,
      default_method = "molten",
    },
  },
  config = function(_, opts)
    require("quarto").setup(opts)

    local function set_runner_keys(buf)
      local runner = require("quarto.runner")
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
      end
      map("n", "<localleader>rc", runner.run_cell, "Run cell")
      map("n", "<localleader>ra", runner.run_above, "Run cell and above")
      map("n", "<localleader>rA", runner.run_all, "Run all cells")
      map("n", "<localleader>rl", runner.run_line, "Run line")
      map("x", "<localleader>r", runner.run_range, "Run visual range")

      local ok, wk = pcall(require, "which-key")
      if ok then wk.add { { "<localleader>r", group = "Quarto Run", buffer = buf } } end
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "quarto",
      group = vim.api.nvim_create_augroup("quarto_runner_keys", { clear = true }),
      callback = function(args) set_runner_keys(args.buf) end,
    })

    -- The FileType event that lazy-loaded this plugin may have already fired
    -- for the current buffer, so bind it directly too.
    if vim.bo.filetype == "quarto" then set_runner_keys(0) end
  end,
}
