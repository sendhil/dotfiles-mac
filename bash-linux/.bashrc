# Shared environment is available to interactive and non-interactive Bash.
dotfiles_config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/dotfiles
[ -r "$dotfiles_config_dir/common.sh" ] && . "$dotfiles_config_dir/common.sh"
[ -r "$dotfiles_config_dir/platform.sh" ] && . "$dotfiles_config_dir/platform.sh"

# Machine- or workplace-specific values belong here. Stow never creates it.
[ -r "$dotfiles_config_dir/local.sh" ] && . "$dotfiles_config_dir/local.sh"

case $- in
  *i*) ;;
  *) unset dotfiles_config_dir; return 0 ;;
esac

[ -r "$HOME/.bash/bash_profile" ] && . "$HOME/.bash/bash_profile"
[ -r "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"
unset dotfiles_config_dir
