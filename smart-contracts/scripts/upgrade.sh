#!/bin/bash
# Magic Swap - Upgrade Script
# Upgrades existing contract to a new version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Magic Swap - Contract Upgrade${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}Error: sui CLI is not installed${NC}"
    exit 1
fi

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Package ID required${NC}"
    echo "Usage: ./upgrade.sh <PACKAGE_ID> [UPGRADE_CAP_ID]"
    echo ""
    echo "Example:"
    echo "  ./upgrade.sh 0x123...abc"
    echo "  ./upgrade.sh 0x123...abc 0x456...def"
    exit 1
fi

PACKAGE_ID=$1
UPGRADE_CAP_ID=$2

# Get current network
NETWORK=$(sui client active-env 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Active Network: ${NC}$NETWORK"
echo -e "${YELLOW}Package ID: ${NC}$PACKAGE_ID"

# Build first
echo -e "\n${YELLOW}Step 1: Building contract...${NC}"
sui move build

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed! Please fix errors before upgrading.${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Run tests
echo -e "\n${YELLOW}Step 2: Running tests...${NC}"
sui move test

if [ $? -ne 0 ]; then
    echo -e "${RED}Tests failed! Please fix tests before upgrading.${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"

# Confirm upgrade
echo -e "\n${YELLOW}Ready to upgrade package on $NETWORK${NC}"
echo -e "${RED}WARNING: Upgrades are irreversible!${NC}"
read -p "Do you want to proceed with upgrade? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Upgrade cancelled."
    exit 0
fi

# Upgrade
echo -e "\n${YELLOW}Step 3: Upgrading contract...${NC}"

if [ -z "$UPGRADE_CAP_ID" ]; then
    echo -e "${YELLOW}Note: No UpgradeCap ID provided. You may need to specify it.${NC}"
    echo "Looking for UpgradeCap in your wallet..."
    
    # Try to find UpgradeCap
    sui client objects --json | jq -r '.[] | select(.type | contains("UpgradeCap")) | .objectId'
fi

sui client upgrade --gas-budget 100000000 --upgrade-capability "$UPGRADE_CAP_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Upgrade successful!${NC}"
else
    echo -e "${RED}Upgrade failed!${NC}"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Upgrade Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify new functionality on-chain"
echo "2. Update any frontend configurations if needed"
