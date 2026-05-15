---@type LazySpec
return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.messages = opts.messages or {}
      -- Noice search counts default to EOL virtual text, which git-blame also uses.
      -- Heirline's cmd_info still shows search count without fighting blame text.
      opts.messages.view_search = false
      return opts
    end,
  },
}
