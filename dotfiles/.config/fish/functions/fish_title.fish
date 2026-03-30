function __profile_display_path
  set --local p (pwd)

  set --local home_re (string escape --style=regex -- "$HOME")
  set p (string replace --regex -- "^$home_re" "~" $p)
  set p (string replace --regex -- '^~/repositories/' '~/r/' $p)
  set p (string replace --regex -- '^~/r/personal/' '~/r/p/' $p)

  echo $p
end

function fish_tab_title --description 'Set terminal window title to shortened PWD'
    set --local title (__profile_display_path)

    if test (id -u) -eq 0
        echo "! $title"
    else
        echo "$title"
    end
end
