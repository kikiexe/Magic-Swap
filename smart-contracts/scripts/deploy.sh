#!/bin/bash
# Magic Swap - Deploy Script
# Deploys the smart contract to the specified network

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Magic Swap - Contract Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}Error: sui CLI is not installed${NC}"
    exit 1
fi

# Get current network
NETWORK=$(sui client active-env 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Active Network: ${NC}$NETWORK"

# Build first
echo -e "\n${YELLOW}Step 1: Building contract...${NC}"
sui move build

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed! Please fix errors before deploying.${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Run tests
echo -e "\n${YELLOW}Step 2: Running tests...${NC}"
sui move test

if [ $? -ne 0 ]; then
    echo -e "${RED}Tests failed! Please fix tests before deploying.${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"

# Confirm deployment
echo -e "\n${YELLOW}Ready to deploy to $NETWORK${NC}"
read -p "Do you want to proceed with deployment? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy
echo -e "\n${YELLOW}Step 3: Deploying contract...${NC}"
RESULT=$(sui client publish --gas-budget 100000000 --json 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment successful!${NC}"
    echo ""
    echo "Deployment Result:"
    echo "$RESULT" | jq '.'
    
    # Extract Package ID
    PACKAGE_ID=$(echo "$RESULT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
    echo -e "\n${GREEN}Package ID: ${NC}$PACKAGE_ID"
    
    # Save to file
    echo "$RESULT" > deployment_result.json
    echo -e "${YELLOW}Full result saved to: deployment_result.json${NC}"
else
    echo -e "${RED}Deployment failed!${NC}"
    echo "$RESULT"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Update PACKAGE_ID in frontend/src/config/sui.js"
echo "2. Extract shared object IDs from deployment_result.json"
echo "3. Update FEE_VAULT_ID, USER_STATS_REGISTRY_ID, EMERGENCY_STATUS_ID"
