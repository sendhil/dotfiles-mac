.PHONY: all
all: stow gitconfig

.PHONY: stow
stow:
	stow -t ~ kitty neovim skhd bash-linux bat yabai karabiner tmux prezto hammerspoon aerospace sesh

.PHONY: unstow
unstow:
	@stow -D -t ~ kitty neovim skhd bash-linux bat yabai karabiner tmux prezto hammerspoon aerospace sesh

.PHONY: gitconfig
gitconfig:
	@cp ~/.gitconfig ~/.old-gitconfig
	@sed -i 's/^\s*//g' ~/.gitconfig
	@crudini --merge ~/.gitconfig < ./git/aliases.ini

.PHONY: prestow
prestow:
	@./non-linked-scripts/clear-out-files-before-stow.sh
