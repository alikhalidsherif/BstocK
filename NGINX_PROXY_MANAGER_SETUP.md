# 🌐 Nginx Proxy Manager Setup for BStock

This guide covers setting up BStock with Nginx Proxy Manager (NPM) and Cloudflare tunnel for `bstock.ashreef.com`.

## 🏗️ Architecture Overview

```
Internet → Cloudflare → Cloudflared Tunnel → Nginx Proxy Manager → BStock Containers
```

**Network Flow:**
- **Cloudflare**: DNS + CDN + DDoS protection
- **Cloudflared Tunnel**: Secure tunnel to your home server (no port forwarding needed)
- **Nginx Proxy Manager**: Reverse proxy with SSL termination and routing
- **BStock**: Frontend + Backend containers on internal networks

## 📋 Prerequisites

### Required Services
- ✅ **Nginx Proxy Manager** running with `npm-network`
- ✅ **Cloudflared tunnel** configured for `bstock.ashreef.com`
- ✅ **Docker** with external network `npm-network` created

### Create NPM Network (if not exists)
```bash
docker network create npm-network
```

## 🚀 Deployment Steps

### 1. Configure Environment
```bash
# Copy and edit environment file
cp production.env .env

# Edit .env with your secure values
nano .env
```

**Required changes in `.env`:**
```env
# Database security
POSTGRES_PASSWORD=your-super-secure-db-password-here

# Backend security  
SECRET_KEY=your-cryptographically-secure-secret-key

# Domain configuration (already set)
DOMAIN=bstock.ashreef.com
CORS_ALLOW_ORIGINS=https://bstock.ashreef.com
```

### 2. Deploy BStock Services
```bash
# Deploy using docker-compose
docker-compose -f docker-compose.prod.yml up -d --build

# Verify services are running
docker-compose -f docker-compose.prod.yml ps
```

### 3. Configure Nginx Proxy Manager

#### Frontend Proxy Host Configuration

**In NPM Admin Panel:**

1. **Add Proxy Host** for Frontend:
   - **Domain Names**: `bstock.ashreef.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: `frontend` (container name)
   - **Forward Port**: `80`
   - **Cache Assets**: ✅ Enabled
   - **Block Common Exploits**: ✅ Enabled
   - **Websockets Support**: ✅ Enabled (for real-time features)

2. **SSL Configuration**:
   - **SSL Certificate**: Request new SSL certificate
   - **Force SSL**: ✅ Enabled
   - **HTTP/2 Support**: ✅ Enabled
   - **HSTS Enabled**: ✅ Enabled
   - **HSTS Subdomains**: ✅ Enabled

3. **Advanced Configuration**:
   ```nginx
   # Add these custom nginx directives
   
   # Security headers
   add_header X-Frame-Options "SAMEORIGIN" always;
   add_header X-Content-Type-Options "nosniff" always;
   add_header X-XSS-Protection "1; mode=block" always;
   add_header Referrer-Policy "strict-origin-when-cross-origin" always;
   
   # Cloudflare real IP
   set_real_ip_from 103.21.244.0/22;
   set_real_ip_from 103.22.200.0/22;
   set_real_ip_from 103.31.4.0/22;
   set_real_ip_from 104.16.0.0/13;
   set_real_ip_from 104.24.0.0/14;
   set_real_ip_from 108.162.192.0/18;
   set_real_ip_from 131.0.72.0/22;
   set_real_ip_from 141.101.64.0/18;
   set_real_ip_from 162.158.0.0/15;
   set_real_ip_from 172.64.0.0/13;
   set_real_ip_from 173.245.48.0/20;
   set_real_ip_from 188.114.96.0/20;
   set_real_ip_from 190.93.240.0/20;
   set_real_ip_from 197.234.240.0/22;
   set_real_ip_from 198.41.128.0/17;
   real_ip_header CF-Connecting-IP;
   
   # API proxy for backend calls
   location /api/ {
       proxy_pass http://backend:8000/;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
       proxy_set_header X-Forwarded-Host $host;
       
       # CORS headers for API
       add_header 'Access-Control-Allow-Origin' 'https://bstock.ashreef.com' always;
       add_header 'Access-Control-Allow-Credentials' 'true' always;
       add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
       add_header 'Access-Control-Allow-Headers' 'Content-Type,Authorization,Accept,Origin,User-Agent,X-Forwarded-For,X-Forwarded-Proto' always;
   }
   ```

#### Optional: Separate API Subdomain

If you want a separate API endpoint (`api.bstock.ashreef.com`):

1. **Add Proxy Host** for API:
   - **Domain Names**: `api.bstock.ashreef.com`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: `backend`
   - **Forward Port**: `8000`
   - **Block Common Exploits**: ✅ Enabled

2. **Update CORS in `.env`**:
   ```env
   CORS_ALLOW_ORIGINS=https://bstock.ashreef.com,https://api.bstock.ashreef.com
   ```

## 🔧 Cloudflare Configuration

### DNS Records
In Cloudflare DNS, ensure you have:

```
Type: CNAME
Name: bstock
Target: your-tunnel-subdomain.cfargotunnel.com
Proxy: ✅ Proxied (orange cloud)
```

### Cloudflared Tunnel Configuration

**In your `config.yml`:**
```yaml
tunnel: your-tunnel-id
credentials-file: /path/to/credentials.json

ingress:
  - hostname: bstock.ashreef.com
    service: http://localhost:80  # NPM port
  - service: http_status:404
```

### Cloudflare Settings

**SSL/TLS Configuration:**
- **SSL/TLS encryption mode**: Full (strict)
- **Always Use HTTPS**: ✅ On
- **Minimum TLS Version**: 1.2
- **TLS 1.3**: ✅ On

**Security Settings:**
- **Security Level**: Medium
- **Bot Fight Mode**: ✅ On
- **Browser Integrity Check**: ✅ On

**Speed Optimization:**
- **Auto Minify**: CSS, JavaScript, HTML ✅
- **Brotli**: ✅ On
- **Early Hints**: ✅ On

## 🔍 Verification Steps

### 1. Check Container Health
```bash
# Verify all containers are healthy
docker-compose -f docker-compose.prod.yml ps

# Check logs for any issues
docker-compose -f docker-compose.prod.yml logs -f
```

### 2. Test Internal Connectivity
```bash
# Test backend health from frontend container
docker-compose -f docker-compose.prod.yml exec frontend curl -f http://backend:8000/health

# Test database connectivity from backend
docker-compose -f docker-compose.prod.yml exec backend curl -f http://localhost:8000/health
```

### 3. Test External Access
```bash
# Test domain resolution
nslookup bstock.ashreef.com

# Test HTTPS access
curl -I https://bstock.ashreef.com

# Test API endpoint
curl -I https://bstock.ashreef.com/api/health
```

### 4. Browser Testing
1. Visit `https://bstock.ashreef.com`
2. Check SSL certificate (should show valid Cloudflare cert)
3. Test login functionality
4. Check browser console for CORS errors
5. Test real-time features (WebSocket connections)

## 🛠️ Troubleshooting

### Common Issues

#### 1. 502 Bad Gateway
**Symptoms**: NPM shows 502 error
**Solutions**:
```bash
# Check if containers are running
docker-compose -f docker-compose.prod.yml ps

# Check container logs
docker-compose -f docker-compose.prod.yml logs backend frontend

# Verify npm-network connectivity
docker network inspect npm-network
```

#### 2. CORS Errors
**Symptoms**: Browser console shows CORS errors
**Solutions**:
1. Verify `CORS_ALLOW_ORIGINS` in `.env` matches your domain
2. Check NPM advanced configuration includes CORS headers
3. Restart backend after CORS changes:
   ```bash
   docker-compose -f docker-compose.prod.yml restart backend
   ```

#### 3. SSL Certificate Issues
**Symptoms**: Browser shows SSL warnings
**Solutions**:
1. Check Cloudflare SSL mode is "Full (strict)"
2. Verify NPM SSL certificate is valid
3. Check Cloudflare Universal SSL is active

#### 4. Database Connection Issues
**Symptoms**: Backend can't connect to database
**Solutions**:
```bash
# Check database health
docker-compose -f docker-compose.prod.yml exec db pg_isready -U bstock_user

# Check database logs
docker-compose -f docker-compose.prod.yml logs db

# Verify internal network
docker network inspect bstock-internal
```

### Health Check Commands

```bash
# Full system health check
echo "=== Container Status ==="
docker-compose -f docker-compose.prod.yml ps

echo "=== Network Connectivity ==="
docker-compose -f docker-compose.prod.yml exec frontend curl -f http://backend:8000/health

echo "=== External Access ==="
curl -I https://bstock.ashreef.com

echo "=== SSL Certificate ==="
echo | openssl s_client -servername bstock.ashreef.com -connect bstock.ashreef.com:443 2>/dev/null | openssl x509 -noout -dates
```

## 📊 Monitoring and Maintenance

### Log Monitoring
```bash
# Monitor all logs in real-time
docker-compose -f docker-compose.prod.yml logs -f

# Monitor specific service
docker-compose -f docker-compose.prod.yml logs -f backend

# Check NPM logs
docker logs nginx-proxy-manager
```

### Performance Monitoring
- **Cloudflare Analytics**: Monitor traffic and performance
- **NPM Access Logs**: Check for unusual patterns
- **Container Resources**: Monitor CPU/memory usage

### Regular Maintenance
1. **Weekly**: Check logs for errors
2. **Weekly**: Verify SSL certificate validity
3. **Monthly**: Update container images
4. **Monthly**: Review Cloudflare security events

## 🔐 Security Best Practices

### Container Security
- ✅ Database not exposed to external networks
- ✅ Internal communication on isolated network
- ✅ Only frontend/backend exposed to NPM network
- ✅ No direct port exposure to host

### Network Security
- ✅ Cloudflare DDoS protection
- ✅ NPM blocks common exploits
- ✅ HTTPS enforced everywhere
- ✅ Secure headers configured

### Application Security
- ✅ API documentation disabled in production
- ✅ Strong database passwords
- ✅ Cryptographically secure JWT secret
- ✅ CORS properly configured

---

**Your BStock application is now ready for production at `https://bstock.ashreef.com`! 🎉**
