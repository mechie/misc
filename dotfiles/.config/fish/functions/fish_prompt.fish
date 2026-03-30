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
  set_color --background normal
  set_color normal
  printf '\n'
end

function fish_prompt
  set --local last_status $status

  if not contains -- --final-rendering $argv
    __transient_prompt
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
