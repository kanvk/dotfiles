-- Single-purpose: register every which-key group title.
--
-- This file is the table of contents for the leader map and the catch-all
-- for non-leader prefixes that vim/built-ins use as group heads (g, [, ],
-- z, <C-w>). Without these labels, which-key falls back to "N keys" in
-- operator-pending popups (e.g., after pressing `c` or `d`).
--
-- Mechanism: astrocore.set_mappings queues `desc`-only entries into
-- which-key.add as group specs. We just declare the prefixes with no
-- callback. Per-plugin keymaps stay in their own spec files so lazy.nvim
-- can defer plugin loads via `keys = {}`.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    opts.mappings = opts.mappings or {}
    for _, mode in ipairs { "n", "x", "o" } do
      opts.mappings[mode] = opts.mappings[mode] or {}
    end

    -- Non-leader prefixes: built-in vim namespaces shown in operator-pending
    -- popups (c<x>, d<x>, y<x>) and standalone normal-mode popups.
    for _, mode in ipairs { "n", "x", "o" } do
      opts.mappings[mode]["g"] = { desc = "Goto" }
      opts.mappings[mode]["["] = { desc = "Previous" }
      opts.mappings[mode]["]"] = { desc = "Next" }
      opts.mappings[mode]["z"] = { desc = "Folds / Scroll" }
    end
    opts.mappings.n["<C-w>"] = { desc = "Window" }

    -- <Leader> as a SUB-prefix (after an operator like c/d/y, or after a
    -- visual selection). In n-mode <Leader> is the root popup so it doesn't
    -- need a sub-prefix label, but in o/x it appears nested and would
    -- otherwise render as "N keys". x-mode has many leader-prefixed children
    -- (Sidekick, Replace, Refactor, Git, Molten, ...); o-mode currently only
    -- has Spider subword motions but more leader-mapped motions could appear.
    opts.mappings.o["<Leader>"] = { desc = "Leader" }
    opts.mappings.x["<Leader>"] = { desc = "Leader" }

    -- Leader group overrides / mode mirrors.
    --
    -- Some groups are titled by upstream packs but with descriptions that
    -- drift from the actual contents — override here. Others need mode
    -- mirrors because their children are mapped in {n,x,o} (e.g., spider's
    -- motions) but the group desc was only registered in n-mode.

    -- <Leader>s: content-search namespace — grep, buffer lines, help,
    -- keymaps, diagnostics, registers, marks, undo, etc. The actual
    -- bindings live in plugins/user.lua. Mode-mirror in x for visual
    -- selection grep.
    opts.mappings.n["<Leader>s"] = { desc = "Search" }
    opts.mappings.x["<Leader>s"] = { desc = "Search" }

    -- <Leader>S: Spider subword motion (capital S to free <Leader>s* for
    -- content search). Mapped in {n,x,o} since spider motions are valid
    -- operator targets (c<Leader>Sw etc.).
    for _, mode in ipairs { "n", "x", "o" } do
      opts.mappings[mode]["<Leader>S"] = { desc = "Subword" }
    end

    -- <Leader>R: was Astro core's "Rename file" (single binding), then
    -- "Remote" via remote-sshfs (shadow). With remote-sshfs removed and
    -- rename redundantly covered by <Leader>fR (Snacks LSP-aware) and
    -- <Leader>lr (LSP symbol rename), repurpose to "Replace" for spectre.
    opts.mappings.n["<Leader>R"] = { desc = "Replace" }
    opts.mappings.x["<Leader>R"] = { desc = "Replace" }

    -- <Leader>x: Astro labels it "Quickfix/Lists" but Trouble dominates
    -- the children (xx/XX/xL/xQ/xt/xT all diagnostic-flavored).
    opts.mappings.n["<Leader>x"] = { desc = "Diagnostics / Lists" }

    -- <Leader>q: previously "Quit / Session" (slash-joined). Session is
    -- implementation detail of "what state to keep when quitting"; verb
    -- is "Quit". Children unchanged (qq/qQ + persistence's qs/qS/ql/qd).
    opts.mappings.n["<Leader>q"] = { desc = "Quit" }

    -- <Leader>gH: GitHub sub-group under Git. Consolidated here from
    -- astrocore.lua so all group titles live in one place.
    opts.mappings.n["<Leader>gH"] = { desc = "GitHub" }
  end,
}
