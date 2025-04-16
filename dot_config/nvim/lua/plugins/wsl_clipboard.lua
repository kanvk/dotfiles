-- Use win32yank for clipboard

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if vim.fn.has "wsl" == 1 then
      opts.options.g.clipboard = {
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
  end,
}
