#!/bin/sh

# Update terminal title to path after each command
set_window_title() {
  printf "\033]0;%s\a" "$(pwd | sed -e "s;^$HOME;~;")"
}
if [ -n "$PROMPT_COMMAND" ]; then
  PROMPT_COMMAND="$PROMPT_COMMAND;set_window_title"
else
  PROMPT_COMMAND=set_window_title
fi

posh() { powershell.exe "$@"; }
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if tput setaf 1 > /dev/null 2>&1; then
  # We have color support, red/green prompt based on $?
  PS1='$([ $? != 0 ] && printf "\[\033[0;31m\]" || printf "\[\033[0;32m\]");\[\033[0;00m\] '
else
  PS1='; '
fi
