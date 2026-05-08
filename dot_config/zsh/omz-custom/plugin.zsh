# djui/alias-tips
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_"

# jeffreytse/zsh-vi-mode
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# Single dispatch at yank time. SSH must win over win32yank: when SSH'd
# into a WSL box, win32yank.exe is still on PATH via WSL interop, but it
# writes to the *WSL host's* Windows clipboard — not the user's local
# clipboard on the SSH client. OSC 52 routes back through the terminal
# regardless of what tools the remote has.
_zvm_clip_copy() {
  if [[ -n $SSH_CONNECTION ]]; then
    _osc52_copy
  elif (( $+commands[win32yank.exe] )); then
    win32yank.exe -i --crlf
  elif [[ -n $DISPLAY ]] && (( $+commands[xclip] )); then
    xclip -selection clipboard
  else
    _osc52_copy
  fi
}
_zvm_clip_paste() {
  if [[ -n $SSH_CONNECTION ]]; then
    :  # terminals refuse OSC 52 paste; nothing reachable
  elif (( $+commands[win32yank.exe] )); then
    win32yank.exe -o --lf
  elif [[ -n $DISPLAY ]] && (( $+commands[xclip] )); then
    xclip -selection clipboard -o
  fi
}
ZVM_CLIPBOARD_COPY_CMD='_zvm_clip_copy'
ZVM_CLIPBOARD_PASTE_CMD='_zvm_clip_paste'

# `gx` opens the URL/path under the cursor. OMZ's open_command resolves
# to xdg-open / open / cmd.exe-start per host; `code` is VS Code everywhere.
ZVM_OPEN_CMD='open_command'
ZVM_OPEN_FILE_CMD='code'
