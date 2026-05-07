vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.autoformat = false

do
  local uv_py = vim.fn.expand "~/.local/share/uv/tools/pynvim/bin/python"
  vim.g.python3_host_prog = vim.fn.executable(uv_py) == 1 and uv_py or vim.fn.exepath "python3"
end

local opt = vim.opt
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.colorcolumn = "120"
opt.relativenumber = true
opt.number = true
opt.signcolumn = "yes"
opt.wrap = false
opt.hidden = true
opt.spell = false
