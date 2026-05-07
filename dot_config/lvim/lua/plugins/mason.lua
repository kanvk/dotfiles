---@type LazySpec
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "mason-org/mason.nvim" },
  cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
  event = "VeryLazy",
  opts = {
    ensure_installed = {
      "lua-language-server",
      "stylua",
      "shfmt",
      "prettierd",
      "cmakelang",
      "markdownlint-cli2",
      "actionlint",
      "yamllint",
      "debugpy",
      "tree-sitter-cli",
      "bash-language-server",
      "shellcheck",
    },
  },
}
