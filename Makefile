.PHONY: all
all: stow gitconfig

.PHONY: stow
stow:
	stow -t ~ kitty neovim vim skhd bash-linux bat yabai karabiner

.PHONY: unstow
unstow:
	@stow -D -t ~ kitty neovim vim skhd bash-linux bat yabai karabiner

.PHONY: gitconfig
gitconfig:
	@cp ~/.gitconfig ~/.old-gitconfig
	@sed -i 's/^\s*//g' ~/.gitconfig
	@crudini --merge ~/.gitconfig < ./git/aliases.ini

.PHONY: prestow
prestow:
	@./non-linked-scripts/clear-out-files-before-stow.sh
