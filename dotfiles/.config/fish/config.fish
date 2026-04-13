if status is-interactive
    set --global fish_transient_prompt 1

    # Async git prompt: per-PID universal variable + repaint on change
    set --global _prompt_git_var _prompt_git_$fish_pid
    set --universal $_prompt_git_var ""

    function _prompt_git_refresh --on-variable _prompt_git_$fish_pid
        commandline -f repaint
    end

    function _prompt_git_cleanup --on-event fish_exit
        set --erase --universal $_prompt_git_var
    end
end

set --global fish_greeting ""
set --global fish_prompt_pwd_dir_length 5
set --global --export EDITOR "code --wait"

if test -f "$HOME/.config/fish/local.secrets.fish"
    source "$HOME/.config/fish/local.secrets.fish"
end
