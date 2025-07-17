#!/bin/bash

# Install the ElizaOS CLI globally from local tarballs
# This allows you to use 'elizaos' command anywhere in your terminal

set -e

echo "=== Installing ElizaOS CLI Globally from Tarballs ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONOREPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to get tarball names
get_tarball_name() {
    local package_dir=$1
    local package_name=$(node -e "console.log(require('$package_dir/package.json').name.replace('@', '').replace('/', '-'))")
    local version=$(node -e "console.log(require('$package_dir/package.json').version)")
    echo "${package_name}-${version}.tgz"
}

echo -e "${YELLOW}Step 1: Preparing packages (resolving workspace dependencies)...${NC}"
cd "$MONOREPO_ROOT"
./scripts/prepare-packages-for-testing.sh

echo -e "${YELLOW}Step 2: Building all packages...${NC}"
bun run build

echo -e "${YELLOW}Step 3: Creating tarballs...${NC}"
cd "$MONOREPO_ROOT/packages/core"
npm pack
CORE_PACK=$(get_tarball_name .)
mv "$CORE_PACK" "$MONOREPO_ROOT/"

cd "$MONOREPO_ROOT/packages/plugin-sql"
npm pack
SQL_PACK=$(get_tarball_name .)
mv "$SQL_PACK" "$MONOREPO_ROOT/"

cd "$MONOREPO_ROOT/packages/plugin-bootstrap"
npm pack
BOOTSTRAP_PACK=$(get_tarball_name .)
mv "$BOOTSTRAP_PACK" "$MONOREPO_ROOT/"

cd "$MONOREPO_ROOT/packages/cli"
npm pack
CLI_PACK=$(get_tarball_name .)
mv "$CLI_PACK" "$MONOREPO_ROOT/"

echo -e "${YELLOW}Step 4: Installing globally...${NC}"
cd "$MONOREPO_ROOT"

# Check if using npm or bun
if command -v bun &> /dev/null; then
    echo -e "${BLUE}Using bun for global installation${NC}"
    
    # Create a temporary directory for installation
    TEMP_INSTALL="/tmp/elizaos-global-install-$(date +%s)"
    mkdir -p "$TEMP_INSTALL"
    cd "$TEMP_INSTALL"
    
    # Initialize package.json
    echo '{"name": "elizaos-global-temp", "version": "1.0.0"}' > package.json
    
    # Install dependencies
    bun add "file:$MONOREPO_ROOT/$CORE_PACK"
    bun add "file:$MONOREPO_ROOT/$SQL_PACK"
    bun add "file:$MONOREPO_ROOT/$BOOTSTRAP_PACK"
    bun add "file:$MONOREPO_ROOT/$CLI_PACK"
    
    # Link globally
    cd node_modules/@elizaos/cli
    bun link
    
    echo -e "${GREEN}✓ ElizaOS CLI installed globally with bun${NC}"
    echo -e "${YELLOW}Note: You may need to add bun's global bin to your PATH:${NC}"
    echo -e "${BLUE}export PATH=\"\$HOME/.bun/bin:\$PATH\"${NC}"
else
    echo -e "${BLUE}Using npm for global installation${NC}"
    
    # Install with npm globally
    npm install -g \
        "file:$MONOREPO_ROOT/$CORE_PACK" \
        "file:$MONOREPO_ROOT/$SQL_PACK" \
        "file:$MONOREPO_ROOT/$BOOTSTRAP_PACK" \
        "file:$MONOREPO_ROOT/$CLI_PACK"
    
    echo -e "${GREEN}✓ ElizaOS CLI installed globally with npm${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Restoring original package.json files...${NC}"
cd "$MONOREPO_ROOT"
find packages -name 'package.json.bak' -exec sh -c 'mv {} ${0%.bak}' {} \;

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Test the installation
echo -e "${YELLOW}Testing installation...${NC}"
which elizaos && echo -e "${GREEN}✓ elizaos command found at: $(which elizaos)${NC}" || echo -e "${RED}✗ elizaos command not found in PATH${NC}"

echo ""
echo -e "${YELLOW}Testing command:${NC}"
elizaos --version || echo -e "${RED}Failed to run elizaos --version${NC}"

echo ""
echo -e "${GREEN}You can now use 'elizaos' command anywhere!${NC}"
echo ""
echo -e "${YELLOW}To uninstall later:${NC}"
if command -v bun &> /dev/null; then
    echo -e "${BLUE}bun unlink @elizaos/cli${NC}"
    echo -e "${BLUE}rm -rf $TEMP_INSTALL${NC}"
else
    echo -e "${BLUE}npm uninstall -g @elizaos/cli${NC}"
fi

echo ""
echo -e "${YELLOW}Cleanup tarballs:${NC}"
echo -e "${BLUE}rm $MONOREPO_ROOT/*.tgz${NC}" 