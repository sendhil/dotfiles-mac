# Portable shell environment. Keep host- and platform-specific values in
# platform.sh or in the optional, untracked local.sh.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":${PATH:-}:" in
    *":$1:"*) ;;
    *)
      if [ -n "${PATH:-}" ]; then
        PATH="$1:$PATH"
      else
        PATH=$1
      fi
      ;;
  esac
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"

export PATH
export EDITOR=nvim
export LESS=FRX
export MANPAGER='nvim +Man!'
export REVIEW_BASE=master
export BAT_THEME=TwoDark
export POWERLEVEL9K_INSTANT_PROMPT=quiet

case $- in
  *i*)
    if command -v dircolors >/dev/null 2>&1; then
      if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
      else
        eval "$(dircolors -b)"
      fi
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'
      alias fgrep='fgrep --color=auto'
      alias egrep='egrep --color=auto'
    fi

    dotfiles_shell=${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}
    if [ -n "$dotfiles_shell" ] && command -v zoxide >/dev/null 2>&1; then
      eval "$(zoxide init "$dotfiles_shell")"
    fi
    unset dotfiles_shell

    if [ -r "$HOME/.local/bin/virtualenvwrapper_lazy.sh" ]; then
      export WORKON_HOME="$HOME/.virtualenvs"
      export PROJECT_HOME="$HOME/src"
      . "$HOME/.local/bin/virtualenvwrapper_lazy.sh"
    fi
    ;;
esac
