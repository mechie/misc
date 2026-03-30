function __aws_config_file
    if set --query AWS_CONFIG_FILE
        echo "$AWS_CONFIG_FILE"
    else
        echo "$HOME/.aws/config"
    end
end

function __aws_config_get --argument section_name key_name
    set --local config_file (__aws_config_file)
    if not test -f "$config_file"
        return 1
    end

    awk -v target="[$section_name]" -v wanted_key="$key_name" '
        /^\s*[#;]/ { next }
        /^\[/ { in_section = ($0 == target) }
        in_section {
            split($0, parts, "=")
            if (length(parts) < 2) {
                next
            }

            key = parts[1]
            sub(/^[[:space:]]+/, "", key)
            sub(/[[:space:]]+$/, "", key)

            value = substr($0, index($0, "=") + 1)
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)

            if (key == wanted_key) {
                print value
                exit
            }
        }
    ' "$config_file"
end

function __aws_sso_context --argument profile_name
    set --local section_name default
    if test "$profile_name" != "default"
        set section_name "profile $profile_name"
    end

    set --local start_url (__aws_config_get "$section_name" sso_start_url)
    set --local sso_region (__aws_config_get "$section_name" sso_region)

    if test -z "$start_url"
        set --local session_ref (__aws_config_get "$section_name" sso_session)
        if test -n "$session_ref"
            set --local session_section "sso-session $session_ref"
            set start_url (__aws_config_get "$session_section" sso_start_url)
            set sso_region (__aws_config_get "$session_section" sso_region)
        end
    end

    if test -z "$start_url" -o -z "$sso_region"
        return 1
    end

    echo (string trim -r -c / "$start_url")
    echo "$sso_region"
end

function __has_valid_sso_device_token --argument sso_start_url sso_region skew_seconds
    if test -z "$sso_start_url" -o -z "$sso_region"
        return 1
    end

    set --local cache_dir "$HOME/.aws/sso/cache"
    if not test -d "$cache_dir"
        return 1
    end

    if not command --search --query jq
        return 1
    end

    set --local must_be_valid_after (math (date -u +%s) + $skew_seconds)
    set --local normalized_start_url (string trim -r -c / "$sso_start_url")

    for file in "$cache_dir"/*.json
        if not test -f "$file"
            continue
        end

        set --local json_start_url (jq -r '.startUrl // empty' "$file" 2>/dev/null | string trim -r -c /)
        set --local json_region (jq -r '.region // empty' "$file" 2>/dev/null)
        set --local expires_at (jq -r '.expiresAt | fromdateiso8601? // empty' "$file" 2>/dev/null)

        if test "$json_start_url" = "$normalized_start_url" -a "$json_region" = "$sso_region" -a -n "$expires_at"
            if test "$expires_at" -gt "$must_be_valid_after"
                return 0
            end
        end
    end

    return 1
end

function aws-login --argument profile_name
    if test -z "$profile_name"
        if set --query AWS_PROFILE
            set profile_name "$AWS_PROFILE"
        else
            echo "; aws configure list-profiles"
            aws configure list-profiles
            echo "aws-login must be called with a profile name from the above" >&2
            return 1
        end
    end

    set --global --export AWS_PROFILE "$profile_name"

    set --local sso_context (__aws_sso_context "$profile_name")
    if test (count $sso_context) -lt 2
        echo "Profile '$profile_name' not SSO-backed, skipping 'aws sso login'"
        return 0
    end

    set --local start_url "$sso_context[1]"
    set --local sso_region "$sso_context[2]"

    if __has_valid_sso_device_token "$start_url" "$sso_region" 3600
        echo "Using cached SSO for '$profile_name'"
        return 0
    end

    aws sso login --profile "$profile_name"
end
