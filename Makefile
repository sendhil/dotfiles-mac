TARGET ?= $(HOME)
export TARGET

PACKAGES := $(sort $(shell ./scripts/package-set.sh macos) $(shell ./scripts/package-set.sh ubuntu))
PACKAGE_STOW_TARGETS := $(addprefix stow-,$(PACKAGES))
PACKAGE_UNSTOW_TARGETS := $(addprefix unstow-,$(PACKAGES))

.PHONY: all
all: stow-macos gitconfig

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make stow-macos      - Preflight and stow common + macOS packages"
	@echo "  make unstow-macos    - Unstow common + macOS packages"
	@echo "  make stow-ubuntu     - Preflight and stow common + Ubuntu packages"
	@echo "  make unstow-ubuntu   - Unstow common + Ubuntu packages"
	@echo "  make preflight-macos - Simulate the macOS Stow operation"
	@echo "  make preflight-ubuntu - Simulate the Ubuntu Stow operation"
	@echo "  make stow-<package>  - Preflight and stow an existing package"
	@echo "  make unstow-<package>- Preflight and unstow an existing package"
	@echo "  make gitconfig       - Update git config with aliases"
	@echo ""
	@echo "Available selected packages:"
	@echo "  $(PACKAGES)"

.PHONY: stow
stow:
	@echo "error: 'make stow' is unsupported; use 'make stow-macos' or 'make stow-ubuntu'" >&2
	@exit 2

.PHONY: unstow
unstow:
	@echo "error: 'make unstow' is unsupported; use 'make unstow-macos' or 'make unstow-ubuntu'" >&2
	@exit 2

.PHONY: preflight-macos
preflight-macos:
	@./scripts/stow-preflight.sh macos "$${TARGET}"

.PHONY: stow-macos
stow-macos: preflight-macos
	@stow --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh macos)

.PHONY: unstow-macos
unstow-macos:
	@stow --simulate --delete --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh macos)
	@stow --delete --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh macos)

.PHONY: preflight-ubuntu
preflight-ubuntu:
	@./scripts/stow-preflight.sh ubuntu "$${TARGET}"

.PHONY: stow-ubuntu
stow-ubuntu: preflight-ubuntu
	@stow --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh ubuntu)

.PHONY: unstow-ubuntu
unstow-ubuntu:
	@stow --simulate --delete --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh ubuntu)
	@stow --delete --no-folding --target "$${TARGET}" $$(./scripts/package-set.sh ubuntu)

.PHONY: $(PACKAGE_STOW_TARGETS)
$(PACKAGE_STOW_TARGETS): stow-%:
	@echo "Preflighting $*..."
	@stow --simulate --no-folding --target "$${TARGET}" "$*"
	@echo "Stowing $*..."
	@stow --no-folding --target "$${TARGET}" "$*"

.PHONY: $(PACKAGE_UNSTOW_TARGETS)
$(PACKAGE_UNSTOW_TARGETS): unstow-%:
	@echo "Preflighting removal of $*..."
	@stow --simulate --delete --no-folding --target "$${TARGET}" "$*"
	@echo "Unstowing $*..."
	@stow --delete --no-folding --target "$${TARGET}" "$*"

.PHONY: gitconfig
gitconfig:
	@cp ~/.gitconfig ~/.old-gitconfig
	@sed -i 's/^\s*//g' ~/.gitconfig
	@crudini --merge ~/.gitconfig < ./git/aliases.ini

.PHONY: prestow
prestow:
	@echo "error: 'make prestow' is retired; use a platform preflight target" >&2
	@exit 2

.PHONY: build-bin
build-bin:
	swiftc -O -o bin/.local/bin/cmux-scratch bin/.local/bin/cmux-scratch.swift
