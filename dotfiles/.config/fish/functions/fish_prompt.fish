function __transient_prompt
  set_color --background 301934

  if fish_is_root_user
    set_color red
    printf '!!'
    set_color normal
    printf ' '
  end

  set_color green
  printf '%s' (prompt_pwd)

  set --local git_info $$_prompt_git_var
  if test -n "$git_info"
    set --local parts (string split '|' -- $git_info)
    set --local state $parts[1]
    set --local branch $parts[2]
    set --local ahead $parts[3]
    set --local behind $parts[4]
    if test "$state" = +
      set_color green
    else
      set_color yellow
    end
    printf ' (%s' $branch
    test -n "$ahead" && printf ' ↑%s' $ahead
    test -n "$behind" && printf ' ↓%s' $behind
    printf ')'
  end

  set_color --background normal
  set_color normal
  printf '\n'
end

function fish_prompt
  set --local last_status $status

  if not contains -- --final-rendering $argv
    __transient_prompt

    # Spawn async git info computation (skip on repaint to avoid infinite loop)
    if not set -q _prompt_is_repaint
      set --global _prompt_is_repaint 1
      command kill $_prompt_git_pid 2>/dev/null
      set --local var $_prompt_git_var
      fish --private --command "
        set -l branch (command git branch --show-current 2>/dev/null)
        if test \$status -eq 0
          if test -z \"\$branch\"
            set branch (command git rev-parse --short HEAD 2>/dev/null)
          end
          set --local state +
          if not command git diff --quiet HEAD 2>/dev/null
            set state !
          end
          set --local ahead ''
          set --local behind ''
          set --local counts (command git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
          if test \$status -eq 0
            set --local lr (string split \t -- \$counts)
            test \$lr[1] -gt 0 && set behind \$lr[1]
            test \$lr[2] -gt 0 && set ahead \$lr[2]
          end
          set --universal $var \"\$state|\$branch|\$ahead|\$behind\"
        else
          set --universal $var ''
        end
      " &
      builtin disown
      set --global _prompt_git_pid $last_pid
    else
      set --erase _prompt_is_repaint
    end
  end

  if test $last_status -ne 0
    set_color red
  else
    set_color green
  end

  printf ';'
  set_color normal
  printf ' '
end
