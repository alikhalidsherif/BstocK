# 🏠 BStock Home Server Deployment Guide

This guide will help you deploy BStock on your home server for testing and development.

## 📋 Prerequisites

### Required Software
- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Docker Compose** v2.0+
- **Git** (to clone/update the repository)

### System Requirements
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: At least 10GB free space
- **Network**: Static IP recommended for consistent access

## 🚀 Quick Start

### 1. Prepare Environment Configuration

1. Copy the production environment template:
   ```bash
   cp production.env .env
   ```

2. Edit `.env` file with your settings:
   ```bash
   # Database Configuration
   POSTGRES_PASSWORD=your-secure-password-here
   
   # Backend Security
   SECRET_KEY=your-super-secret-key-here
   
   # Network Configuration (update with your server IP)
   CORS_ALLOW_ORIGINS=http://192.168.1.100:3000,http://localhost:3000
   FRONTEND_PORT=3000
   BACKEND_PORT=8000
   DB_PORT=5432
   ```

### 2. Generate Secure Keys

Generate a secure secret key for production:
```bash
python -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))"
```

### 3. Deploy with Docker Compose

#### Option A: Using PowerShell Script (Windows)
```powershell
.\scripts\deploy.ps1
```

#### Option B: Using Bash Script (Linux/Mac)
```bash
./scripts/deploy.sh
```

#### Option C: Manual Deployment
```bash
# Create necessary directories
mkdir -p backups logs

# Start services
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps
```

## 🌐 Access Your Application

After successful deployment:

- **Frontend (Flutter Web)**: http://localhost:3000 or http://YOUR_SERVER_IP:3000
- **Backend API**: http://localhost:8000 or http://YOUR_SERVER_IP:8000
- **API Documentation**: http://localhost:8000/docs (if DISABLE_OPENAPI=false)
- **Database**: localhost:5432 (internal access only)

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `POSTGRES_PASSWORD` | Database password | - | ✅ |
| `SECRET_KEY` | JWT secret key | - | ✅ |
| `CORS_ALLOW_ORIGINS` | Allowed frontend origins | localhost:3000 | ✅ |
| `FRONTEND_PORT` | Frontend port | 3000 | ❌ |
| `BACKEND_PORT` | Backend port | 8000 | ❌ |
| `DB_PORT` | Database port | 5432 | ❌ |
| `DISABLE_OPENAPI` | Hide API docs | true | ❌ |

### Network Configuration

For access from other devices on your network:

1. **Find your server IP**:
   ```bash
   # Windows
   ipconfig
   
   # Linux/Mac
   ip addr show
   ```

2. **Update CORS settings** in `.env`:
   ```bash
   CORS_ALLOW_ORIGINS=http://192.168.1.100:3000,http://localhost:3000
   ```

3. **Configure firewall** (if needed):
   ```bash
   # Windows Firewall
   # Allow ports 3000 and 8000 through Windows Defender Firewall
   
   # Linux (ufw)
   sudo ufw allow 3000
   sudo ufw allow 8000
   ```

## 🛠️ Management Commands

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f db
```

### Restart Services
```bash
# Restart all
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Update Application
```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build
```

## 💾 Database Management

### Create Backup
```bash
# Using script
./scripts/backup.sh

# Manual backup
docker-compose -f docker-compose.prod.yml --profile backup run --rm db-backup
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

### Database Access
```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U bstock_user -d stock_db
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] **Strong passwords**: Use secure passwords for database
- [ ] **Secret key**: Generate cryptographically secure secret key
- [ ] **CORS origins**: Limit to your actual domains/IPs
- [ ] **API docs**: Disable in production (`DISABLE_OPENAPI=true`)
- [ ] **Firewall**: Configure firewall rules appropriately
- [ ] **Updates**: Keep Docker images and dependencies updated
- [ ] **Backups**: Set up regular database backups
- [ ] **SSL/TLS**: Consider using reverse proxy with SSL for external access

### Reverse Proxy Setup (Optional)

For SSL/TLS and domain-based access, consider using:
- **Nginx Proxy Manager** (GUI-based)
- **Traefik** (Docker-native)
- **Caddy** (Automatic HTTPS)

## 🐛 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker is running
docker info

# Check logs for errors
docker-compose -f docker-compose.prod.yml logs

# Check disk space
df -h
```

#### Database Connection Issues
```bash
# Check database health
docker-compose -f docker-compose.prod.yml exec db pg_isready -U bstock_user

# Reset database (⚠️ DATA LOSS)
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d
```

#### Frontend Can't Connect to Backend
1. Check CORS configuration in `.env`
2. Verify backend is accessible: `curl http://localhost:8000/health`
3. Check network connectivity between containers

#### Port Conflicts
```bash
# Check what's using ports
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000

# Change ports in .env file
FRONTEND_PORT=3001
BACKEND_PORT=8001
```

### Health Checks

```bash
# Check all services are healthy
docker-compose -f docker-compose.prod.yml ps

# Test endpoints
curl http://localhost:8000/health  # Backend health
curl http://localhost:3000/health  # Frontend health
```

## 📊 Monitoring

### Resource Usage
```bash
# Container stats
docker stats

# Disk usage
docker system df
```

### Log Rotation
Logs are automatically rotated (max 10MB, 3 files per service).

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks

1. **Weekly**: Check logs for errors
2. **Weekly**: Create database backup
3. **Monthly**: Update base Docker images
4. **Monthly**: Clean up old Docker images: `docker system prune`

### Update Workflow
```bash
# 1. Backup database
./scripts/backup.sh

# 2. Pull latest code
git pull origin main

# 3. Update and restart services
docker-compose -f docker-compose.prod.yml up -d --build

# 4. Verify everything works
docker-compose -f docker-compose.prod.yml ps
```

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose -f docker-compose.prod.yml logs`
2. Verify configuration in `.env` file
3. Ensure Docker Desktop is running
4. Check system resources (RAM, disk space)
5. Review this documentation for troubleshooting steps

---

**Happy deploying! 🎉**
