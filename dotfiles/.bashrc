#!/bin/sh

posh() { powershell.exe "$@"; }
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
PS1='$([ $? != 0 ] && echo "\[\e[0;31m\]");\[\e[0;00m\] '
