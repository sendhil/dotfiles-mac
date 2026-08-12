# Enable the Powerlevel10k instant prompt when its generated cache exists.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

dotfiles_config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/dotfiles
[[ -r "$dotfiles_config_dir/common.sh" ]] && source "$dotfiles_config_dir/common.sh"
[[ -r "$dotfiles_config_dir/platform.sh" ]] && source "$dotfiles_config_dir/platform.sh"

# Machine- or workplace-specific values belong here. Stow never creates it.
[[ -r "$dotfiles_config_dir/local.sh" ]] && source "$dotfiles_config_dir/local.sh"

[[ -r "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]] && source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
[[ -r "$HOME/.bash/bash_profile" ]] && source "$HOME/.bash/bash_profile"
[[ -r "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

unset dotfiles_config_dir
