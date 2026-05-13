---@type LazySpec
return {
  { "metakirby5/codi.vim", cmd = "Codi" },
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = { style = "percent", output_extension = "auto", force_ft = nil },
  },
  {
    "benlubas/molten-nvim",
    version = "^1",
    build = ":UpdateRemotePlugins",
    cmd = { "MoltenInit", "MoltenEvaluateLine", "MoltenEvaluateVisual", "MoltenReevaluateCell" },
    init = function() vim.g.molten_image_provider = "image.nvim" end,
  },
  -- Overseer under <Leader>O* = "Overseer" group (parity with nvim's
  -- relocation off the m/M case-pair). LazyVim ships no overseer keymaps;
  -- previously only the dashboard `r` action invoked :OverseerRun. Group
  -- title is in plugins/keymaps.lua.
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerOpen", "OverseerToggle", "OverseerRun", "OverseerShell", "OverseerTaskAction" },
    keys = {
      { "<Leader>Ot", "<cmd>OverseerToggle<cr>",      desc = "Toggle Overseer" },
      { "<Leader>Oc", "<cmd>OverseerShell<cr>",       desc = "Run Command" },
      { "<Leader>Or", "<cmd>OverseerRun<cr>",         desc = "Run Task" },
      { "<Leader>Oa", "<cmd>OverseerTaskAction<cr>",  desc = "Task Action" },
      { "<Leader>Oi", "<cmd>checkhealth overseer<cr>", desc = "Overseer Info" },
    },
    opts = {},
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, require "neotest-python" {
        runner = "pytest",
        dap = { justMyCode = false },
      })
    end,
  },
}
