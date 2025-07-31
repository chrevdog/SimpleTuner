#!/bin/bash

# SimpleTuner Update Script
# This script automates the process of updating SimpleTuner and rebuilding the Docker image

set -e

echo "🔄 Starting SimpleTuner update process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    print_error "Please run this script from the root directory of the SimpleTuner Docker project"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(git -C SimpleTuner describe --tags --abbrev=0 2>/dev/null || echo "unknown")
print_status "Current SimpleTuner version: $CURRENT_VERSION"

# Step 1: Fetch latest changes from upstream
print_status "Fetching latest changes from upstream..."
git fetch upstream

# Step 2: Check if there are updates
UPSTREAM_COMMITS=$(git log HEAD..upstream/main --oneline | wc -l)
if [ "$UPSTREAM_COMMITS" -eq 0 ]; then
    print_warning "No updates available. SimpleTuner is already up to date."
    exit 0
fi

print_status "Found $UPSTREAM_COMMITS new commits from upstream"

# Step 3: Merge upstream changes
print_status "Merging upstream changes..."
git checkout main
git merge upstream/main

# Step 4: Update SimpleTuner submodule
print_status "Updating SimpleTuner submodule..."
cd SimpleTuner
git pull origin main
cd ..

# Get new version
NEW_VERSION=$(git -C SimpleTuner describe --tags --abbrev=0 2>/dev/null || echo "latest")
print_status "Updated SimpleTuner version: $NEW_VERSION"

# Step 5: Build Docker image
print_status "Building Docker image..."
docker build -t theloupedevteam/simpletuner-docker:latest .

# Step 6: Tag with version
if [ "$NEW_VERSION" != "latest" ]; then
    print_status "Tagging Docker image with version $NEW_VERSION..."
    docker tag theloupedevteam/simpletuner-docker:latest theloupedevteam/simpletuner-docker:$NEW_VERSION
fi

# Step 7: Ask user if they want to push to Docker Hub
echo ""
read -p "Do you want to push the Docker image to Docker Hub? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Pushing to Docker Hub..."
    docker push theloupedevteam/simpletuner-docker:latest
    
    if [ "$NEW_VERSION" != "latest" ]; then
        docker push theloupedevteam/simpletuner-docker:$NEW_VERSION
    fi
    
    print_success "Successfully pushed to Docker Hub"
else
    print_warning "Skipping Docker Hub push"
fi

# Step 8: Ask user if they want to commit and push changes
echo ""
read -p "Do you want to commit and push changes to Git? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Committing changes..."
    git add .
    git commit -m "Update SimpleTuner to $NEW_VERSION"
    
    print_status "Pushing to Git repository..."
    git push origin main
    
    print_success "Successfully pushed changes to Git"
else
    print_warning "Skipping Git push"
fi

print_success "Update process completed!"
print_status "New SimpleTuner version: $NEW_VERSION"
print_status "Docker image: theloupedevteam/simpletuner-docker:latest"
if [ "$NEW_VERSION" != "latest" ]; then
    print_status "Versioned image: theloupedevteam/simpletuner-docker:$NEW_VERSION"
fi 