#!/bin/bash
# Magic Swap - Verify Script
# Runs build and tests to verify contract integrity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Magic Swap - Contract Verification${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}Error: sui CLI is not installed${NC}"
    exit 1
fi

# Build
echo -e "\n${YELLOW}Step 1: Building contract...${NC}"
sui move build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

# Test
echo -e "\n${YELLOW}Step 2: Running tests...${NC}"
sui move test

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Tests FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All tests passed${NC}"

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Verification Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Build: OK${NC}"
echo -e "${GREEN}✓ Tests: OK${NC}"
echo ""
echo "Contract is ready for deployment."
