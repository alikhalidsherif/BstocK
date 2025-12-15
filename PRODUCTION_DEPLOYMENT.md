# 🚀 BStock Production Deployment Guide

**Domain**: `bstock.ashreef.com`  
**Architecture**: Docker + Nginx Proxy Manager + Cloudflare Tunnel

## 🏗️ Infrastructure Overview

```
Internet → Cloudflare CDN → Cloudflared Tunnel → Nginx Proxy Manager → BStock Containers
                                                        ↓
                                               ┌─────────────────┐
                                               │   npm-network   │
                                               │                 │
                                               │  ┌─────────────┐│
                                               │  │  frontend   ││
                                               │  │   :80       ││
                                               │  └─────────────┘│
                                               │         │       │
                                               │  ┌─────────────┐│
                                               │  │   backend   ││
                                               │  │   :8000     ││
                                               │  └─────────────┘│
                                               └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │ bstock-internal │
                                               │                 │
                                               │  ┌─────────────┐│
                                               │  │ database    ││
                                               │  │   :5432     ││
                                               │  └─────────────┘│
                                               └─────────────────┘
```

## 📋 Prerequisites

### Infrastructure Requirements
- ✅ **Docker & Docker Compose** installed
- ✅ **Nginx Proxy Manager** running with `npm-network`
- ✅ **Cloudflare account** with domain `ashreef.com`
- ✅ **Cloudflared tunnel** configured

### Network Setup
```bash
# Ensure npm-network exists (script will create if missing)
docker network create npm-network
```

## 🚀 Quick Deployment

### 1. Clone and Configure
```bash
# Navigate to project directory
cd /path/to/BStock

# Copy production environment template
cp production.env .env

# Edit environment variables (REQUIRED!)
nano .env
```

### 2. Configure Environment Variables

**Critical settings in `.env`:**
```env
# Database Security (CHANGE THESE!)
POSTGRES_PASSWORD=your-super-secure-database-password-here

# Backend Security (CHANGE THIS!)
SECRET_KEY=your-cryptographically-secure-jwt-secret-key

# Domain Configuration (already configured)
DOMAIN=bstock.ashreef.com
CORS_ALLOW_ORIGINS=https://bstock.ashreef.com

# Environment
ENVIRONMENT=production
DISABLE_OPENAPI=true
```

**Generate secure secret key:**
```bash
python -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))"
```

### 3. Deploy Services
```bash
# Deploy using PowerShell script (Windows)
.\scripts\deploy.ps1

# OR deploy manually
docker-compose -f docker-compose.prod.yml up -d --build
```

### 4. Configure Nginx Proxy Manager

**See detailed guide**: [NGINX_PROXY_MANAGER_SETUP.md](./NGINX_PROXY_MANAGER_SETUP.md)

**Quick setup:**
1. Add proxy host for `bstock.ashreef.com`
2. Forward to `frontend` container on port `80`
3. Enable SSL with Let's Encrypt
4. Add custom nginx config for API routing

## 🔧 Configuration Details

### Docker Networks

**Two isolated networks for security:**

1. **`bstock-internal`** (isolated):
   - Database container
   - Internal communication only
   - No external access

2. **`npm-network`** (external):
   - Frontend and backend containers
   - Connected to Nginx Proxy Manager
   - Internet-facing through NPM

### Container Configuration

| Service | Network | Ports | Purpose |
|---------|---------|-------|---------|
| `db` | `bstock-internal` | `5432` (internal) | PostgreSQL database |
| `backend` | `bstock-internal` + `npm-network` | `8000` (internal) | FastAPI application |
| `frontend` | `bstock-internal` + `npm-network` | `80` (internal) | Flutter web app |

### Security Features

- ✅ **Database isolation**: No external network access
- ✅ **No direct port exposure**: All traffic through NPM
- ✅ **HTTPS enforcement**: SSL termination at NPM
- ✅ **CORS protection**: Configured for production domain
- ✅ **Security headers**: Configured in nginx
- ✅ **API documentation disabled**: In production mode

## 🌐 Domain and SSL Configuration

### Cloudflare DNS
```
Type: CNAME
Name: bstock
Target: your-tunnel-id.cfargotunnel.com
Proxy: ✅ Proxied (orange cloud)
```

### Cloudflare Settings
- **SSL/TLS Mode**: Full (strict)
- **Always Use HTTPS**: ✅ On
- **Min TLS Version**: 1.2
- **Auto Minify**: CSS, JS, HTML ✅

### Nginx Proxy Manager
- **Domain**: `bstock.ashreef.com`
- **Forward to**: `frontend:80`
- **SSL**: Let's Encrypt certificate
- **Force SSL**: ✅ Enabled
- **HTTP/2**: ✅ Enabled

## 📊 Monitoring and Health Checks

### Container Health Checks
```bash
# Check all services status
docker-compose -f docker-compose.prod.yml ps

# View real-time logs
docker-compose -f docker-compose.prod.yml logs -f

# Check specific service
docker-compose -f docker-compose.prod.yml logs -f backend
```

### Application Health Endpoints
- **Frontend**: `https://bstock.ashreef.com/health`
- **Backend**: `https://bstock.ashreef.com/api/health`
- **Database**: Internal health checks only

### Automated Health Checks
All containers include health checks:
- **Database**: `pg_isready` every 10s
- **Backend**: HTTP health endpoint every 30s
- **Frontend**: HTTP health endpoint every 30s

## 💾 Backup and Recovery

### Automated Database Backups
```bash
# Create backup
docker-compose -f docker-compose.prod.yml --profile backup run --rm db-backup

# Using backup script
.\scripts\backup.sh  # Windows
./scripts/backup.sh  # Linux/Mac
```

### Backup Schedule (Optional)
Set up cron job for regular backups:
```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/BStock && docker-compose -f docker-compose.prod.yml --profile backup run --rm db-backup
```

### Restore from Backup
```bash
# Stop services
docker-compose -f docker-compose.prod.yml down

# Start only database
docker-compose -f docker-compose.prod.yml up -d db

# Restore backup
docker-compose -f docker-compose.prod.yml exec db psql -U bstock_user -d stock_db < backups/backup_YYYYMMDD_HHMMSS.sql

# Start all services
docker-compose -f docker-compose.prod.yml up -d
```

## 🔄 Updates and Maintenance

### Application Updates
```bash
# 1. Backup database
.\scripts\backup.sh

# 2. Pull latest code
git pull origin main

# 3. Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build

# 4. Verify deployment
docker-compose -f docker-compose.prod.yml ps
```

### Container Updates
```bash
# Update base images
docker-compose -f docker-compose.prod.yml pull

# Rebuild with latest images
docker-compose -f docker-compose.prod.yml up -d --build
```

### Cleanup
```bash
# Remove unused images and containers
docker system prune -f

# Remove unused volumes (⚠️ BE CAREFUL!)
docker volume prune
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Services Won't Start
```bash
# Check Docker daemon
docker info

# Check logs for errors
docker-compose -f docker-compose.prod.yml logs

# Check system resources
df -h  # Disk space
free -h  # Memory
```

#### 2. NPM Can't Reach Containers
```bash
# Verify npm-network exists
docker network inspect npm-network

# Check container network connectivity
docker-compose -f docker-compose.prod.yml exec frontend ping backend

# Verify containers are on npm-network
docker network inspect npm-network | grep -A 10 "Containers"
```

#### 3. Database Connection Issues
```bash
# Check database health
docker-compose -f docker-compose.prod.yml exec db pg_isready -U bstock_user

# Test connection from backend
docker-compose -f docker-compose.prod.yml exec backend curl http://localhost:8000/health

# Check database logs
docker-compose -f docker-compose.prod.yml logs db
```

#### 4. CORS Errors
```bash
# Verify CORS configuration
docker-compose -f docker-compose.prod.yml exec backend env | grep CORS

# Restart backend after CORS changes
docker-compose -f docker-compose.prod.yml restart backend

# Check browser console for specific CORS errors
```

### Debug Commands
```bash
# Enter container shell
docker-compose -f docker-compose.prod.yml exec backend bash
docker-compose -f docker-compose.prod.yml exec frontend sh

# Check container environment
docker-compose -f docker-compose.prod.yml exec backend env

# Test internal connectivity
docker-compose -f docker-compose.prod.yml exec frontend curl http://backend:8000/health
```

## 📈 Performance Optimization

### Cloudflare Optimizations
- ✅ **Brotli compression**: Enabled
- ✅ **Auto minification**: CSS, JS, HTML
- ✅ **Browser caching**: Configured
- ✅ **Image optimization**: Cloudflare Polish

### Nginx Optimizations
- ✅ **Gzip compression**: Enabled in frontend nginx
- ✅ **Static asset caching**: 1 year cache headers
- ✅ **HTTP/2**: Enabled in NPM
- ✅ **Connection keep-alive**: Configured

### Database Optimizations
- ✅ **Connection pooling**: SQLAlchemy configured
- ✅ **Persistent volumes**: Data survives container restarts
- ✅ **Health checks**: Prevent traffic to unhealthy DB

## 🔐 Security Checklist

### Pre-Deployment Security
- [ ] **Strong passwords**: Database and JWT secrets
- [ ] **Environment variables**: All secrets in `.env` file
- [ ] **API documentation**: Disabled in production
- [ ] **CORS origins**: Limited to production domain
- [ ] **Network isolation**: Database on internal network only

### Post-Deployment Security
- [ ] **SSL certificate**: Valid and auto-renewing
- [ ] **Security headers**: Configured in NPM
- [ ] **Cloudflare protection**: DDoS and bot protection enabled
- [ ] **Access logs**: Monitor for suspicious activity
- [ ] **Regular updates**: Keep containers and base images updated

### Ongoing Security
- [ ] **Log monitoring**: Regular review of application logs
- [ ] **Backup verification**: Test restore procedures
- [ ] **Certificate monitoring**: Ensure SSL doesn't expire
- [ ] **Dependency updates**: Keep application dependencies current

## 📞 Support and Resources

### Documentation
- **Nginx Proxy Manager Setup**: [NGINX_PROXY_MANAGER_SETUP.md](./NGINX_PROXY_MANAGER_SETUP.md)
- **Home Server Guide**: [HOME_SERVER_DEPLOYMENT.md](./HOME_SERVER_DEPLOYMENT.md)
- **Application README**: [README.md](./README.md)

### Useful Commands Reference
```bash
# View all services
docker-compose -f docker-compose.prod.yml ps

# Follow logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend

# Scale service (if needed)
docker-compose -f docker-compose.prod.yml up -d --scale backend=2

# Stop all services
docker-compose -f docker-compose.prod.yml down

# Stop and remove volumes (⚠️ DATA LOSS)
docker-compose -f docker-compose.prod.yml down -v
```

---

**Your BStock application is now production-ready at `https://bstock.ashreef.com`! 🎉**

**Next Steps:**
1. Configure Nginx Proxy Manager (see [NGINX_PROXY_MANAGER_SETUP.md](./NGINX_PROXY_MANAGER_SETUP.md))
2. Set up monitoring and alerting
3. Configure automated backups
4. Test disaster recovery procedures
