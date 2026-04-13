if status is-interactive
    set --global fish_transient_prompt 1
end

set --global fish_greeting ""
set --global fish_prompt_pwd_dir_length 5
set --global --export EDITOR "code --wait"

if test -f "$HOME/.config/fish/local.secrets.fish"
    source "$HOME/.config/fish/local.secrets.fish"
end
