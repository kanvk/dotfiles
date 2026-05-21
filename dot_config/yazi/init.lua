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
