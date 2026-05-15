vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.autoformat = false

-- Prefer the uv-tool-managed pynvim venv; on Windows uv keeps tool venvs
-- under %APPDATA%\uv\tools with a `Scripts\python.exe` layout.
do
  local candidates = { vim.fn.expand "~/.local/share/uv/tools/pynvim/bin/python" }
  if vim.fn.has "win32" == 1 then
    table.insert(candidates, vim.fn.expand "$APPDATA/uv/tools/pynvim/Scripts/python.exe")
    table.insert(candidates, vim.fn.expand "~/.local/share/uv/tools/pynvim/Scripts/python.exe")
  end
  for _, p in ipairs(candidates) do
    if vim.fn.executable(p) == 1 then
      vim.g.python3_host_prog = p
      break
    end
  end
  if not vim.g.python3_host_prog then
    vim.g.python3_host_prog = vim.fn.exepath(vim.fn.has "win32" == 1 and "python" or "python3")
  end
end

-- Wire pwsh as the shell on native Windows so `:!`, toggleterm, lazygit,
-- :Mason, etc. behave. See `:h shell-powershell`.
if vim.fn.has "win32" == 1 then
  local pwsh = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell"
  vim.opt.shell = pwsh
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
    .. "$PSStyle.OutputRendering='plaintext';"
  vim.opt.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.opt.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
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
opt.listchars = "tab:→ ,eol:¶,space:·,trail:▒,nbsp:␣,extends:»,precedes:«"

if vim.fn.has "wsl" == 1 and not (vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT) then
  vim.g.clipboard = {
    name = "WSL-Clipboard",
    copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
    paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
    cache_enabled = true,
  }
end
