-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "lua-language-server",

        -- install formatters
        "stylua",
        "shfmt", -- bash/zsh formatter
        "prettierd", -- json/yaml/md/etc on demand
        "cmakelang", -- provides cmake-format and cmake-lint

        -- install linters
        "markdownlint-cli2", -- markdown linting
        "actionlint", -- GitHub Actions YAML
        "yamllint", -- general YAML linting

        -- install debuggers
        "debugpy",

        -- install any other package
        "tree-sitter-cli",
      },
    },
  },
}
