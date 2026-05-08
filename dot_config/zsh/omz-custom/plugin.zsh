# djui/alias-tips
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_"

# jeffreytse/zsh-vi-mode
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# ZVM evals these, so any pipeline works. Without an explicit cmd, ZVM
# autodetects xclip on Linux but never finds win32yank — and a hardcoded
# xclip silently fails over SSH (no $DISPLAY). Re-dispatch at yank time
# so OSC 52 takes over when X is unreachable, mirroring the c/csc aliases.
if (( $+commands[win32yank.exe] )); then
  ZVM_CLIPBOARD_COPY_CMD='win32yank.exe -i --crlf'
  ZVM_CLIPBOARD_PASTE_CMD='win32yank.exe -o --lf'
elif (( $+commands[xclip] )); then
  _zvm_clip_copy()  { if [[ -n $DISPLAY ]]; then xclip -selection clipboard;    else _osc52_copy; fi }
  _zvm_clip_paste() { [[ -n $DISPLAY ]] && xclip -selection clipboard -o }
  ZVM_CLIPBOARD_COPY_CMD='_zvm_clip_copy'
  ZVM_CLIPBOARD_PASTE_CMD='_zvm_clip_paste'
fi

# `gx` opens the URL/path under the cursor. OMZ's open_command resolves
# to xdg-open / open / cmd.exe-start per host; `code` is VS Code everywhere.
ZVM_OPEN_CMD='open_command'
ZVM_OPEN_FILE_CMD='code'
