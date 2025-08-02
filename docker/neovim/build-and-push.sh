#!/bin/bash

# Build and push script for Docker Hub
# Usage: ./build-and-push.sh [dockerhub-username] [tag] [--no-cache]

set -e

# Configuration
DOCKER_USERNAME="${1:-sendhil}"
IMAGE_NAME="neovim-dev"
TAG="${2:-latest}"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

# Check for --no-cache flag
NO_CACHE=""
for arg in "$@"; do
    if [ "$arg" = "--no-cache" ]; then
        NO_CACHE="--no-cache"
        echo "🔧 No-cache mode enabled - forcing fresh build"
    fi
done

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🐳 Docker Hub Build and Push Script${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""
echo "Image: ${FULL_IMAGE_NAME}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker/neovim/Dockerfile.standalone" ]; then
    echo -e "${RED}❌ Error: Must run from repository root${NC}"
    echo "Please run from dotfiles-mac directory"
    exit 1
fi

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running${NC}"
    exit 1
fi

# Build for multiple architectures using buildx
echo -e "${YELLOW}🔨 Setting up Docker buildx...${NC}"
docker buildx create --use --name neovim-builder 2>/dev/null || docker buildx use neovim-builder

echo -e "${YELLOW}🏗️  Building multi-architecture image...${NC}"
echo "Architectures: linux/amd64, linux/arm64"

# Build and push in one step for multi-arch
# Disable log rate limiting to see all output
export BUILDKIT_STEP_LOG_MAX_SPEED=-1
export BUILDKIT_STEP_LOG_MAX_SIZE=-1

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -f docker/neovim/Dockerfile.standalone \
    -t "${FULL_IMAGE_NAME}" \
    --push \
    --progress=plain \
    $NO_CACHE \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully built and pushed ${FULL_IMAGE_NAME}${NC}"
    echo ""
    echo -e "${BLUE}To run the image:${NC}"
    echo "  docker run -it --rm ${FULL_IMAGE_NAME}"
    echo ""
    echo -e "${BLUE}To run with a workspace:${NC}"
    echo "  docker run -it --rm -v \$(pwd):/workspace ${FULL_IMAGE_NAME}"
    echo ""
    echo -e "${BLUE}To run with persistent data:${NC}"
    echo "  docker run -it --rm \\"
    echo "    -v neovim-data:/home/nvimuser/.local/share/nvim \\"
    echo "    -v neovim-mason:/home/nvimuser/.local/share/nvim/mason \\"
    echo "    ${FULL_IMAGE_NAME}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Clean up builder
docker buildx rm neovim-builder 2>/dev/null || true