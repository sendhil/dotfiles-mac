# macOS-only shell environment.
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
  dotfiles_brew_prefix=$(brew --prefix 2>/dev/null || true)
  if [ -n "${ZSH_VERSION:-}" ] && [ -d "$dotfiles_brew_prefix/share/zsh/site-functions" ]; then
    fpath=("$dotfiles_brew_prefix/share/zsh/site-functions" $fpath)
  fi
  unset dotfiles_brew_prefix
fi

path_prepend "$HOME/Library/Python/3.9/bin"
export COCOAPODS_DISABLE_DETERMINISTIC_UUIDS=true

darkMode() {
  defaults read -g AppleInterfaceStyle 2>/dev/null
}

alias clearderiveddata='rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"*'
alias localip="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
