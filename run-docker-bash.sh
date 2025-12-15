#!/bin/bash
# Build and run the bash monitor in Docker

echo "================================================"
echo "  Building Docker Container for Bash Monitor"
echo "================================================"
echo ""

# Build the Docker image
docker-compose -f docker-compose-bash.yml build

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  Starting Bash Monitor Container"
    echo "================================================"
    echo ""
    
    # Run the container
    docker-compose -f docker-compose-bash.yml up
else
    echo ""
    echo "❌ Build failed! Please check the error messages above."
    exit 1
fi
