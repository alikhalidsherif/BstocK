#!/bin/bash

# BStock Home Server Deployment Script
# This script helps deploy BStock to your home server

set -e

echo "🚀 BStock Home Server Deployment"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  No .env file found. Creating from production template...${NC}"
    cp production.env .env
    echo -e "${RED}🔧 IMPORTANT: Edit .env file with your actual values before continuing!${NC}"
    echo -e "${RED}   - Update POSTGRES_PASSWORD${NC}"
    echo -e "${RED}   - Update SECRET_KEY${NC}"
    echo -e "${RED}   - Update CORS_ALLOW_ORIGINS with your server IP${NC}"
    echo ""
    read -p "Press Enter after updating .env file..."
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install it and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p backups
mkdir -p logs

# Pull latest images
echo "📦 Pulling latest base images..."
docker-compose -f docker-compose.prod.yml pull db

# Build and start services
echo "🔨 Building and starting services..."
docker-compose -f docker-compose.prod.yml up --build -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🏥 Checking service health..."
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up (healthy)"; then
    echo -e "${GREEN}✅ Services are healthy!${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may still be starting up. Check logs if needed.${NC}"
fi

# Show running services
echo ""
echo "📊 Running services:"
docker-compose -f docker-compose.prod.yml ps

# Show access information
echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo ""
echo "📱 Access your application:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8000"
echo "   Database: localhost:5432"
echo ""
echo "📋 Useful commands:"
echo "   View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   Stop services: docker-compose -f docker-compose.prod.yml down"
echo "   Restart: docker-compose -f docker-compose.prod.yml restart"
echo "   Backup DB: docker-compose -f docker-compose.prod.yml --profile backup run db-backup"
echo ""
echo -e "${YELLOW}💡 Remember to configure your router/firewall to allow access from other devices!${NC}"
