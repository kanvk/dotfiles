# marlonrichert/zsh-autocomplete
# zstyle ':autocomplete:*' insert-unambiguous yes # yes, no (breaks with menu-select)
zstyle ':autocomplete:*' fzf-completion yes # yes, no
zstyle ':autocomplete:*' widget-style menu-select # complete-word, menu-complete, menu-select
zstyle ':autocomplete:*' min-delay 0.3  # seconds (float)

# colored-man-pages
less_termcap[so]="${fg_bold[yellow]}${bg[black]}" # Remove man page footer highlight

# djui/alias-tips
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_"
