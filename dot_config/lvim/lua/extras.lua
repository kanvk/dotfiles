---@type LazySpec
return {
  { import = "lazyvim.plugins.extras.lang.cmake" },
  { import = "lazyvim.plugins.extras.lang.clangd" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.git" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.java" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.julia" },
  { import = "lazyvim.plugins.extras.lang.kotlin" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.php" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.ruby" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.scala" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.terraform" },
  { import = "lazyvim.plugins.extras.lang.toml" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.zig" },

  { import = "lazyvim.plugins.extras.linting.eslint" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },

  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.test.core" },

  { import = "lazyvim.plugins.extras.editor.illuminate" },
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.editor.outline" },
  { import = "lazyvim.plugins.extras.editor.inc-rename" }, -- LSP rename with command-preview
  { import = "lazyvim.plugins.extras.editor.dial" }, -- <C-a>/<C-x> on dates, semver, booleans, hex, alphabet
  { import = "lazyvim.plugins.extras.ai.sidekick" },
  { import = "lazyvim.plugins.extras.coding.yanky" },
  { import = "lazyvim.plugins.extras.ui.treesitter-context" }, -- adds a <leader>ut toggle and a 3-line cap (replaces the manual spec in editor.lua)
  { import = "lazyvim.plugins.extras.util.dot" }, -- chezmoi/dotfiles language support — relevant: this repo IS chezmoi
  { import = "lazyvim.plugins.extras.util.mini-hipatterns" }, -- inline color preview for hex/rgb/Tailwind
}
