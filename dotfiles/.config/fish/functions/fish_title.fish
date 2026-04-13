function fish_title --description 'Set terminal title to shortened PWD'
    if test (id -u) -eq 0
        printf "! "
    end
    printf '%s' (prompt_pwd)
end
