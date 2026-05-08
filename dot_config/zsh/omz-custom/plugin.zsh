# djui/alias-tips
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_"

# jeffreytse/zsh-vi-mode
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# ZVM evals these, so any pipeline works. Without an explicit cmd, ZVM
# autodetects xclip/xsel/wl-clipboard on Linux but never finds win32yank
# — and on bare Linux a hardcoded win32yank cmd would silently fail.
if (( $+commands[win32yank.exe] )); then
  ZVM_CLIPBOARD_COPY_CMD='win32yank.exe -i --crlf'
  ZVM_CLIPBOARD_PASTE_CMD='win32yank.exe -o --lf'
elif (( $+commands[xclip] )); then
  ZVM_CLIPBOARD_COPY_CMD='xclip -selection clipboard'
  ZVM_CLIPBOARD_PASTE_CMD='xclip -selection clipboard -o'
fi

# `gx` opens the URL/path under the cursor. OMZ's open_command resolves
# to xdg-open / open / cmd.exe-start per host; `code` is VS Code everywhere.
ZVM_OPEN_CMD='open_command'
ZVM_OPEN_FILE_CMD='code'
