-- chrisbra/unicode.vim — name lookup for arbitrary chars.
-- Lazy on every :Unicode*/:Digraphs/:DownloadUnicode command.
-- Skipping insert-mode <C-X><C-G>/<C-X><C-Z> completions and the <F4>
-- digraph mapping intentionally — they need startup init, and the CTF
-- use case (UnicodeName on cursor) is purely command-driven. Run
-- `:Lazy load unicode.vim` once if you ever want the completions live.
--
-- First :UnicodeName call may prompt to run :DownloadUnicode to fetch
-- the UnicodeData.txt cache.

---@type LazySpec
return {
  "chrisbra/unicode.vim",
  cmd = { "UnicodeName", "UnicodeSearch", "UnicodeTable", "Digraphs", "DownloadUnicode", "UnicodeCache" },
}
