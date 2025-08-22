#!/bin/bash

# Build script for Cloudflare Dynamic DNS Docker image

echo "Building Cloudflare Dynamic DNS Docker image..."

# Build the Docker image
docker build -t cloudflare-dynamic-dns .

echo "Build complete!"
echo ""
echo "To run the container:"
echo "docker run --env-file ./env.list --rm cloudflare-dynamic-dns"
echo ""
echo "Make sure to create an env.list file with your Cloudflare credentials first."
