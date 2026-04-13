function dump-brew
  pushd $HOME && brew bundle dump \
    --global \
    --force \
    --no-vscode \
    --no-go \
    --no-cargo \
    --no-uv \
    --no-flatpak \
    --no-krew \
    --no-npm
  popd
end
