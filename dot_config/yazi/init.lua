-- Plugin setup (plugins themselves are installed via `ya pkg install`).
require("full-border"):setup { type = ui.Border.ROUNDED }
require("git"):setup { order = 1500 }

-- Status bar (left): show " -> target" when hovering a symlink.
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

-- Status bar (left): git branch of the current view's CWD.
-- Cached per-cwd: status callbacks fire on every redraw, so a fresh shell-out
-- to `git` here would freeze the UI. Refresh only when the cwd changes.
local git_branch_cache = { cwd = nil, branch = "" }
local function current_git_branch(cwd_str)
	if cwd_str == git_branch_cache.cwd then
		return git_branch_cache.branch
	end
	git_branch_cache.cwd = cwd_str
	local handle = io.popen("git -C " .. ("%q"):format(cwd_str) .. " branch --show-current 2>/dev/null")
	if not handle then
		git_branch_cache.branch = ""
		return ""
	end
	local out = handle:read("*l") or ""
	handle:close()
	git_branch_cache.branch = out
	return out
end

Status:children_add(function()
	local cwd = cx.active.current.cwd
	if not cwd then
		return ""
	end
	local branch = current_git_branch(tostring(cwd))
	if branch == "" then
		return ""
	end
	return ui.Line {
		" ",
		ui.Span(" " .. branch):fg("green"),
		" ",
	}
end, 3000, Status.LEFT)

-- Status bar (right): mtime of the hovered file, "YYYY-MM-DD HH:MM" (minute precision).
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or not h.cha or not h.cha.mtime then
		return ""
	end
	local t = math.floor(h.cha.mtime)
	if t <= 0 then
		return ""
	end
	return ui.Line {
		ui.Span(os.date("%Y-%m-%d %H:%M", t)):fg("darkgray"),
		" ",
	}
end, 400, Status.RIGHT)

-- Status bar (right): owner:group of the hovered file.
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	}
end, 500, Status.RIGHT)

-- Header (left): user@host. Yellow when running over SSH, blue otherwise.
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
	local is_ssh = os.getenv("SSH_TTY") or os.getenv("SSH_CONNECTION") or os.getenv("SSH_CLIENT")
	local color = is_ssh and "yellow" or "blue"
	return ui.Span(" " .. ya.user_name() .. "@" .. ya.host_name() .. " "):fg(color):bold()
end, 500, Header.LEFT)
