#!/bin/bash

# CLO835 Final Project - Background Image Switcher
# This script helps you quickly change the background image during demos

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}CLO835 Background Image Switcher${NC}"
echo

# Configuration
NAMESPACE=${NAMESPACE:-"fp"}
CONFIGMAP=${CONFIGMAP:-"webapp-config"}
S3_BUCKET=${S3_BUCKET_NAME:-"clo835fp-bg-images"}

# Available background images
declare -A BACKGROUNDS
BACKGROUNDS["1"]="default-bg.jpg"
BACKGROUNDS["2"]="blue-theme.jpg"
BACKGROUNDS["3"]="green-theme.jpg"
BACKGROUNDS["4"]="professional-bg.jpg"

# Show current background
echo -e "${BLUE}Current Configuration:${NC}"
CURRENT_URL=$(kubectl get configmap $CONFIGMAP -n $NAMESPACE -o jsonpath='{.data.BACKGROUND_IMAGE_URL}' 2>/dev/null || echo "ConfigMap not found")
echo "Current background: $CURRENT_URL"
echo

# Show available options
echo -e "${YELLOW}Available Background Images:${NC}"
for key in "${!BACKGROUNDS[@]}"; do
    filename="${BACKGROUNDS[$key]}"
    if [[ "$CURRENT_URL" == *"$filename"* ]]; then
        echo "  $key) $filename ${GREEN}(current)${NC}"
    else
        echo "  $key) $filename"
    fi
done
echo

# Get user choice
echo "Select a background image (1-4) or press Enter to cancel:"
read -r choice

if [[ -z "$choice" ]]; then
    echo "Cancelled."
    exit 0
fi

if [[ ! "${BACKGROUNDS[$choice]}" ]]; then
    echo -e "${RED}Invalid choice. Please select 1-4.${NC}"
    exit 1
fi

selected_image="${BACKGROUNDS[$choice]}"
new_url="s3://$S3_BUCKET/background-images/$selected_image"

echo -e "${BLUE}Changing background to: $selected_image${NC}"
echo "New URL: $new_url"

# Update ConfigMap
kubectl patch configmap $CONFIGMAP -n $NAMESPACE --type merge -p "{\"data\":{\"BACKGROUND_IMAGE_URL\":\"$new_url\"}}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ConfigMap updated successfully${NC}"
    
    # Restart deployment to pick up new config
    echo -e "${BLUE}Restarting webapp deployment to apply changes...${NC}"
    kubectl rollout restart deployment/webapp-deployment -n $NAMESPACE
    
    # Wait for rollout
    echo "Waiting for deployment to complete..."
    kubectl rollout status deployment/webapp-deployment -n $NAMESPACE --timeout=120s
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Deployment restarted successfully${NC}"
        echo -e "${GREEN}✓ Background image changed to: $selected_image${NC}"
        echo
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Wait 30-60 seconds for the application to download the new image"
        echo "2. Refresh your browser to see the new background"
        echo "3. Check application logs: kubectl logs -f deployment/webapp-deployment -n $NAMESPACE"
    else
        echo -e "${RED}❌ Deployment restart failed${NC}"
    fi
else
    echo -e "${RED}❌ Failed to update ConfigMap${NC}"
fi