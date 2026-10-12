# List of all packages
PACKAGES = sketchybar kitty neovim skhd bash-linux bat yabai karabiner tmux prezto hammerspoon aerospace sesh fd direnv wezterm zellij ccstatusline devservices cmux ghostty bin herdr
STOW_PACKAGES = $(filter-out herdr,$(PACKAGES))

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
	@echo "  make setup-herdr     - Deploy Herdr and install/apply pinned Radar"
	@echo "  make check-herdr     - Verify Herdr/Radar deployment"
	@echo ""
	@echo "Available packages:"
	@echo "  $(PACKAGES)"

.PHONY: stow
stow: stow-herdr
	stow -t ~ $(STOW_PACKAGES)

.PHONY: unstow
unstow: unstow-herdr
	@stow -D -t ~ $(STOW_PACKAGES)

# Herdr owns generated main-config blocks; only Radar preferences are linked.
.PHONY: stow-herdr unstow-herdr setup-herdr check-herdr
stow-herdr:
	@bash ./scripts/setup-herdr-mac.sh --deploy-only

unstow-herdr:
	@bash ./scripts/setup-herdr-mac.sh --unlink-preferences

setup-herdr:
	@bash ./scripts/setup-herdr-mac.sh $(HERDR_SETUP_ARGS)

check-herdr:
	@bash ./scripts/setup-herdr-mac.sh --check

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
	@./scripts/clear-out-files-before-stow.sh

.PHONY: build-bin
build-bin:
	swiftc -O -o bin/.local/bin/cmux-scratch bin/.local/bin/cmux-scratch.swift
