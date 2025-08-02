# Neovim Docker Environment

This directory contains Docker configurations for running Neovim in a containerized environment. Perfect for testing the configuration without installing dependencies on your host system.

## Quick Start

### Using Docker Hub (Pre-built Image)

```bash
# Run interactive shell (drops into bash)
docker run -it --rm sendhil/neovim-dev

# Run Neovim directly
docker run -it --rm sendhil/neovim-dev nvim

# Run with current directory mounted
docker run -it --rm -v $(pwd):/workspace sendhil/neovim-dev

# Run with home directory mounted
docker run -it --rm -v $HOME:/workspace sendhil/neovim-dev

# Run with persistent data volumes
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  -v $(pwd):/workspace \
  sendhil/neovim-dev

# Run with BOTH persistent data AND home directory mounted
docker run -it --rm \
  -v neovim-data:/home/nvimuser/.local/share/nvim \
  -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \
  -v $HOME:/workspace \
  sendhil/neovim-dev
```

### Using Docker Compose (Local Build)

```bash
# Build and start the container
docker-compose up -d

# Enter Neovim
docker-compose exec neovim nvim

# Or get a shell
docker-compose exec neovim bash
```

### Building Locally

```bash
# Build the standalone image
cd /path/to/dotfiles-mac
docker build -f docker/neovim/Dockerfile.standalone -t neovim-dev .

# Run your local build
docker run -it --rm neovim-dev
```

## Features

### Docker Compose Benefits

1. **Live Configuration Editing**
   - Your local `neovim/.config/nvim` is mounted as a volume
   - Edit configs on your host with any editor
   - Changes reflect immediately in the container

2. **Persistent State**
   - Mason installations persist between sessions
   - Neovim data, cache, and state are preserved
   - No need to reinstall language servers each time

3. **Resource Management**
   - CPU and memory limits configured
   - Prevents container from consuming excessive resources

### What's Included

- **Base OS**: Ubuntu 22.04
- **Neovim**: Latest stable version with full configuration
- **Languages**: Go, Node.js (via fnm), Rust, Python 3
- **Tools**: git, fzf, ripgrep, fd, GitHub CLI, uv, vectorcode
- **Compilers**: gcc, g++, clangd, clang-tidy
- **Pre-installed**: All plugins and language servers configured in mason.lua

### Architecture Support

The Docker image supports both x86_64 and ARM64 architectures:
- **x86_64**: Uses pre-built binaries (nvim-linux64)
- **ARM64**: Uses pre-built binaries (nvim-linux-arm64)

## Common Tasks

### Install Language Servers

```bash
# Inside the container
docker-compose exec neovim bash

# Then in Neovim
nvim
:Mason
:MasonToolsInstall
```

### Reset Everything

```bash
# Stop and remove containers
docker-compose down

# Remove all data volumes
docker volume rm neovim-mason-data neovim-local-data neovim-state-data neovim-cache-data

# Rebuild fresh
docker-compose build --no-cache
docker-compose up -d
```

### Mount a Workspace

Edit `docker-compose.yml` and uncomment the workspace volume:

```yaml
volumes:
  # ... other volumes ...
  - ./workspace:/home/nvimuser/workspace
```

Then create a workspace directory and restart:

```bash
mkdir workspace
docker-compose restart
```

## Colima Alternative (macOS)

If you prefer using Colima (a lightweight VM alternative to Docker Desktop):

```bash
# Run the setup script
../../scripts/setup-colima-neovim.sh

# Use the helper commands
colima-nvim ssh     # SSH into VM
colima-nvim nvim    # Start Neovim directly
colima-nvim stop    # Stop the VM
```

## Troubleshooting

### Container won't start
- Check Docker is running: `docker ps`
- View logs: `docker-compose logs neovim`

### Neovim plugins not loading
- Inside container: `:Lazy sync`
- Check health: `:checkhealth`

### Permission issues
- The container runs as user `nvimuser` (UID 1000)
- Ensure your local files have appropriate permissions

### Slow performance on macOS
- Docker Desktop file sharing can be slow
- Try Colima instead for better performance
- Or adjust Docker Desktop resources in preferences

### Language servers failing
- Some LSPs need network access (configured in docker-compose)
- Check Mason logs: `:MasonLog`
- Try manual install: `:MasonInstall <package>`

## Development Workflow

1. Edit configs on your host machine
2. Test changes immediately in the container
3. Commit changes when satisfied
4. Container preserves your Mason installations

This setup provides a clean, reproducible environment for Neovim development without polluting your host system.