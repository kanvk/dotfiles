-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Wire pwsh as the shell on native Windows so `:!`, toggleterm, lazygit,
-- :Mason, plugin update-from-git fallbacks, etc. behave. Cribbed from
-- `:h shell-powershell`; prefer pwsh (PowerShell 7+) but fall back to the
-- bundled `powershell` if only Windows PowerShell 5.1 is available.
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
