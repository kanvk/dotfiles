-- Use OSC 52 for clipboard when in an SSH session

---@type LazySpec
return {
  "ojroques/nvim-osc52",
  lazy = true, -- loaded on demand when clipboard provider calls require('osc52')
  cond = function() return vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil end,
  opts = {
    max_length = 0, -- no limit
    trim = false,
  },
  init = function()
    if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT then
      local function copy(lines, _)
        require("osc52").copy(table.concat(lines, "\n"))
      end

      local function paste()
        return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" }
      end

      vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }

      vim.opt.clipboard = "unnamedplus"
    end
  end,
}
