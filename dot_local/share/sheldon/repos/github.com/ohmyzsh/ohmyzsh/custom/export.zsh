export PATH=/home/kanvk/.local/bin:/home/kanvk/.cargo/bin:/home/kanvk/go/bin:$PATH
export VISUAL='lvim'
export EDITOR='lvim'
export LVIM_DEV_MODE=1
export SUDO_EDITOR=/home/kanvk/.local/bin/lvim
export GPG_TTY=$TTY
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1

# Less pager config
export LESS="-R --mouse --wheel-lines=3"
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Less termcap colors (ignored, using colored-man-pages instead)
# export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
# export LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
# export LESS_TERMCAP_me=$(tput sgr0)
# export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
# export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
# export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
# export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
# export LESS_TERMCAP_mr=$(tput rev)
# export LESS_TERMCAP_mh=$(tput dim)
# export LESS_TERMCAP_ZN=$(tput ssubm)
# export LESS_TERMCAP_ZV=$(tput rsubm)
# export LESS_TERMCAP_ZO=$(tput ssupm)
# export LESS_TERMCAP_ZW=$(tput rsupm)

# Perl
PATH="/home/kanvk/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/kanvk/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/kanvk/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/kanvk/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/kanvk/perl5"; export PERL_MM_OPT;
