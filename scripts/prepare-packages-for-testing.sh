#!/bin/bash

# Prepare packages for testing by resolving workspace dependencies
# This fixes the "workspace:*" issue when testing packages outside the monorepo

set -e

echo "=== Preparing Packages for NPM Testing ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the current version from lerna.json
VERSION=$(node -e "console.log(require('./lerna.json').version)")
echo -e "${YELLOW}Current version: $VERSION${NC}"

# Function to replace workspace:* with actual version
replace_workspace_deps() {
    local package_dir=$1
    local package_name=$(basename "$package_dir")
    
    echo -e "${YELLOW}Processing $package_name...${NC}"
    
    # Create a backup of package.json
    cp "$package_dir/package.json" "$package_dir/package.json.bak"
    
    # Replace workspace:* with the current version
    # This handles all @elizaos/* packages
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$package_dir/package.json', 'utf8'));
        
        // Replace workspace:* in dependencies
        if (pkg.dependencies) {
            Object.keys(pkg.dependencies).forEach(dep => {
                if (pkg.dependencies[dep] === 'workspace:*' && dep.startsWith('@elizaos/')) {
                    pkg.dependencies[dep] = '$VERSION';
                    console.log('  Replaced ' + dep + ': workspace:* -> $VERSION');
                }
            });
        }
        
        // Replace workspace:* in devDependencies
        if (pkg.devDependencies) {
            Object.keys(pkg.devDependencies).forEach(dep => {
                if (pkg.devDependencies[dep] === 'workspace:*' && dep.startsWith('@elizaos/')) {
                    pkg.devDependencies[dep] = '$VERSION';
                    console.log('  Replaced ' + dep + ': workspace:* -> $VERSION');
                }
            });
        }
        
        // Replace workspace:* in peerDependencies
        if (pkg.peerDependencies) {
            Object.keys(pkg.peerDependencies).forEach(dep => {
                if (pkg.peerDependencies[dep] === 'workspace:*' && dep.startsWith('@elizaos/')) {
                    pkg.peerDependencies[dep] = '$VERSION';
                    console.log('  Replaced ' + dep + ': workspace:* -> $VERSION');
                }
            });
        }
        
        fs.writeFileSync('$package_dir/package.json', JSON.stringify(pkg, null, 2));
    "
}

# Process core packages first
echo -e "${GREEN}Processing core packages...${NC}"
replace_workspace_deps "packages/core"
replace_workspace_deps "packages/plugin-sql"
replace_workspace_deps "packages/plugin-bootstrap"
replace_workspace_deps "packages/cli"
replace_workspace_deps "packages/server"

# Process other packages if needed
if [ "$1" == "--all" ]; then
    echo -e "${GREEN}Processing all packages...${NC}"
    for package_dir in packages/*; do
        if [ -f "$package_dir/package.json" ]; then
            replace_workspace_deps "$package_dir"
        fi
    done
fi

echo ""
echo -e "${GREEN}✓ Packages prepared for testing!${NC}"
echo ""
echo "Next steps:"
echo "1. Run 'bun run build' to build all packages"
echo "2. Use npm pack to create tarballs"
echo "3. Install the tarballs in a test directory"
echo ""
echo "To restore original package.json files:"
echo "  find packages -name 'package.json.bak' -exec sh -c 'mv {} {%.bak}' \\;" 