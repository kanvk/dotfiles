vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.autoformat = false

-- Tool-dir precedence matches `uv tool dir`:
-- $UV_TOOL_DIR > $XDG_DATA_HOME/uv/tools > OS default.
do
  local is_win = vim.fn.has "win32" == 1
  local tool_dir = vim.env.UV_TOOL_DIR
  if not tool_dir or tool_dir == "" then
    local xdg = vim.env.XDG_DATA_HOME
    if xdg and xdg ~= "" then
      tool_dir = xdg .. "/uv/tools"
    elseif is_win and vim.env.APPDATA then
      tool_dir = vim.env.APPDATA .. "/uv/tools"
    else
      tool_dir = vim.fn.expand "~/.local/share/uv/tools"
    end
  end
  local exe = tool_dir .. (is_win and "/pynvim/Scripts/python.exe" or "/pynvim/bin/python")
  vim.g.python3_host_prog = vim.fn.executable(exe) == 1 and exe or vim.fn.exepath(is_win and "python" or "python3")
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
