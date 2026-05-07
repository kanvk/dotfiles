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
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle" },
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
