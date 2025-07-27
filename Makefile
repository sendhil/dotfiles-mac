# List of all packages
PACKAGES = kitty neovim skhd bash-linux bat yabai karabiner tmux prezto hammerspoon aerospace sesh fd direnv

.PHONY: all
all: stow gitconfig

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make stow            - Stow all packages"
	@echo "  make unstow          - Unstow all packages"
	@echo "  make stow-<package>  - Stow individual package (e.g., make stow-neovim)"
	@echo "  make unstow-<package>- Unstow individual package (e.g., make unstow-neovim)"
	@echo "  make gitconfig       - Update git config with aliases"
	@echo "  make prestow         - Clear out files before stowing"
	@echo ""
	@echo "Available packages:"
	@echo "  $(PACKAGES)"

.PHONY: stow
stow:
	stow -t ~ $(PACKAGES)

.PHONY: unstow
unstow:
	@stow -D -t ~ $(PACKAGES)

# Pattern rule for individual package stowing
.PHONY: stow-%
stow-%:
	@if echo "$(PACKAGES)" | grep -qw "$*"; then \
		echo "Stowing $*..."; \
		stow -t ~ $*; \
	else \
		echo "Error: Package '$*' not found."; \
		echo "Available packages: $(PACKAGES)"; \
		exit 1; \
	fi

# Pattern rule for individual package unstowing
.PHONY: unstow-%
unstow-%:
	@if echo "$(PACKAGES)" | grep -qw "$*"; then \
		echo "Unstowing $*..."; \
		stow -D -t ~ $*; \
	else \
		echo "Error: Package '$*' not found."; \
		echo "Available packages: $(PACKAGES)"; \
		exit 1; \
	fi

.PHONY: gitconfig
gitconfig:
	@cp ~/.gitconfig ~/.old-gitconfig
	@sed -i 's/^\s*//g' ~/.gitconfig
	@crudini --merge ~/.gitconfig < ./git/aliases.ini

.PHONY: prestow
prestow:
	@./non-linked-scripts/clear-out-files-before-stow.sh
