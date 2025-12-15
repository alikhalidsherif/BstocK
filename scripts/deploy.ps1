# BStock Home Server Deployment Script (PowerShell)
# This script helps deploy BStock to your home server

param(
    [switch]$SkipEnvCheck
)

Write-Host "🚀 BStock Production Deployment (bstock.ashreef.com)" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path ".env") -and -not $SkipEnvCheck) {
    Write-Host "⚠️  No .env file found. Creating from production template..." -ForegroundColor Yellow
    Copy-Item "production.env" ".env"
    Write-Host "🔧 IMPORTANT: Edit .env file with your actual values before continuing!" -ForegroundColor Red
    Write-Host "   - Update POSTGRES_PASSWORD" -ForegroundColor Red
    Write-Host "   - Update SECRET_KEY" -ForegroundColor Red
    Write-Host "   - Update CORS_ALLOW_ORIGINS with your server IP" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter after updating .env file"
}

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker and try again." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is available
try {
    docker-compose version | Out-Null
    Write-Host "✅ Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not available. Please install it and try again." -ForegroundColor Red
    exit 1
}

# Create necessary directories
Write-Host "📁 Creating necessary directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "backups" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# Pull latest images
Write-Host "📦 Pulling latest base images..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml pull db

# Build and start services
Write-Host "🔨 Building and starting services..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml up --build -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Check service health
Write-Host "🏥 Checking service health..." -ForegroundColor Cyan
$services = docker-compose -f docker-compose.prod.yml ps
if ($services -match "Up \(healthy\)") {
    Write-Host "✅ Services are healthy!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some services may still be starting up. Check logs if needed." -ForegroundColor Yellow
}

# Show running services
Write-Host ""
Write-Host "📊 Running services:" -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml ps

# Check npm-network exists
Write-Host "🌐 Checking npm-network..." -ForegroundColor Cyan
try {
    docker network inspect npm-network | Out-Null
    Write-Host "✅ npm-network found" -ForegroundColor Green
} catch {
    Write-Host "⚠️  npm-network not found. Creating it..." -ForegroundColor Yellow
    docker network create npm-network
    Write-Host "✅ npm-network created" -ForegroundColor Green
}

# Show access information
Write-Host ""
Write-Host "🎉 Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Access your application:" -ForegroundColor Cyan
Write-Host "   Production URL: https://bstock.ashreef.com"
Write-Host "   (Configure Nginx Proxy Manager to route to 'frontend' container on port 80)"
Write-Host ""
Write-Host "🔧 Container Access (internal):" -ForegroundColor Cyan
Write-Host "   Frontend container: frontend:80 (on npm-network)"
Write-Host "   Backend container: backend:8000 (on npm-network)"
Write-Host "   Database: db:5432 (internal network only)"
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs: docker-compose -f docker-compose.prod.yml logs -f"
Write-Host "   Stop services: docker-compose -f docker-compose.prod.yml down"
Write-Host "   Restart: docker-compose -f docker-compose.prod.yml restart"
Write-Host "   Backup DB: docker-compose -f docker-compose.prod.yml --profile backup run db-backup"
Write-Host ""
Write-Host "📖 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Configure Nginx Proxy Manager for bstock.ashreef.com"
Write-Host "   2. Point domain to 'frontend' container on port 80"
Write-Host "   3. Set up SSL certificate in NPM"
Write-Host "   4. Configure Cloudflare tunnel if not already done"
Write-Host ""
Write-Host "📚 See NGINX_PROXY_MANAGER_SETUP.md for detailed configuration!" -ForegroundColor Yellow
