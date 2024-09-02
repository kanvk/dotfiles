-- Use win32yank for clipboard
local M = {}

M.setup = function()
  if vim.fn.has "wsl" == 1 then
    vim.g.clipboard = {
      name = "WSL-Clipboard",
      copy = {
        ["+"] = "win32yank.exe -i --crlf",
        ["*"] = "win32yank.exe -i --crlf",
      },
      paste = {
        ["+"] = "win32yank.exe -o --lf",
        ["*"] = "win32yank.exe -o --lf",
      },
      cache_enabled = true,
    }
  end
end

---@type LazySpec
return M
