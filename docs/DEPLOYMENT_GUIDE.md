# BstocK Deployment Playbook

> Maintained by AshReef Labs to keep every deployment of **BstocK by AshReef Labs** consistent, secure, and on-brand.

Unified reference for every supported deployment target. The legacy markdown guides
(`HOME_SERVER_DEPLOYMENT.md`, `PRODUCTION_DEPLOYMENT.md`, `NGINX_PROXY_MANAGER_SETUP.md`,
`BUILD_SCRIPT_USAGE.md`, `frontend/VERCEL_DEPLOYMENT.md`, and `backend/deployment_guide.md`)
have been merged here for easier maintenance.

## Quick Reference

| Target | Path / Tooling | Highlights |
| --- | --- | --- |
| Home server & production clusters | `docker-compose.prod.yml`, `scripts/deploy.(ps1|sh)` | Full stack (Flutter web + FastAPI + Postgres) behind Docker networks |
| Reverse proxy & edge | Nginx Proxy Manager + Cloudflare Tunnel | SSL termination, API routing, Cloudflare WAF/CDN |
| Backend PaaS | Render, Heroku, Railway, DigitalOcean | `backend/` directory deployable as-is with Procfile |
| Frontend hosting | Vercel (`vercel-flutter`), static hosts, custom build pipeline | `frontend/` + `build_flutter.sh` |
| Automated builds | `build_flutter.sh`, GitHub Actions, Netlify, Firebase Hosting | Installs Flutter SDK and produces `frontend/build/web` bundle |

---

## 1. Shared Prerequisites & Environment

1. **Clone & install toolchain**
   - Git, Docker (Desktop or Engine) and Docker Compose v2+
   - Python 3.10+ for backend tooling
   - Flutter 3.4.3+ if you need to hack locally (CI uses bundled script)
2. **Prepare environment variables**
   ```bash
   cp production.env .env
   python -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))"
   ```
3. **Mandatory values**
   - `POSTGRES_PASSWORD` – strong DB password
   - `SECRET_KEY` – JWT signing key (32+ url-safe chars)
   - `CORS_ALLOW_ORIGINS` – comma separated list of allowed frontends
   - `DOMAIN` / `ENVIRONMENT` / `DISABLE_OPENAPI` for production lockdown

Keep `.env` out of source control. All deployment paths below assume the file
is present at the repository root.

---

## 2. Containerized Deployment (Home Lab or Cloud VM)

### Quick Start

```powershell
# Windows
.\scripts\deploy.ps1
```

```bash
# Linux/macOS
./scripts/deploy.sh
# or manually
docker-compose -f docker-compose.prod.yml up -d --build
```

Default ports:
- Frontend (Flutter web): `http://localhost:3000`
- Backend API: `http://localhost:8000`
- API docs: `http://localhost:8000/docs` (set `DISABLE_OPENAPI=false` to expose)

### Ongoing Management

```bash
# Tail logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart a service
docker-compose -f docker-compose.prod.yml restart backend

# Stop stack
docker-compose -f docker-compose.prod.yml down
```

### Backups & Restore

```bash
# Create backup (script)
./scripts/backup.sh

# Ad-hoc backup profile
docker-compose -f docker-compose.prod.yml --profile backup run --rm db-backup

# Restore
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d db
docker-compose -f docker-compose.prod.yml exec db \
  psql -U bstock_user -d stock_db < backups/backup_YYYYMMDD_HHMMSS.sql
docker-compose -f docker-compose.prod.yml up -d
```

### Security Checklist

- Change every default secret before exposing the stack
- Keep the database on the internal `bstock-internal` network only
- Disable OpenAPI in production (`DISABLE_OPENAPI=true`)
- Restrict `CORS_ALLOW_ORIGINS` to real domains/IPs
- Schedule backups + image updates (`docker system prune`, `docker-compose pull`)

---

## 3. Reverse Proxy & Cloudflare Hardening

**Network Flow**
```
Internet → Cloudflare → Cloudflared Tunnel → Nginx Proxy Manager → Docker services
```

1. **Cloudflare**
   - DNS CNAME: `bstock` → `your-tunnel-id.cfargotunnel.com` (proxy ON)
   - SSL/TLS: Full (strict), TLS ≥ 1.2, Always Use HTTPS ON, Brotli & Early Hints ON
   - Tunnel snippet (`config.yml`):
     ```yaml
     ingress:
       - hostname: bstock.ashreef.com
         service: http://localhost:80  # NPM
       - service: http_status:404
     ```

2. **Nginx Proxy Manager**
   - Create `npm-network` (`docker network create npm-network`) and attach frontend/backend containers
   - Proxy Host for `bstock.ashreef.com` → `frontend:80`, enable SSL + HTTP/2 + HSTS
   - Advanced config (extract):
     ```nginx
     add_header X-Frame-Options "SAMEORIGIN" always;
     add_header X-Content-Type-Options "nosniff" always;
     add_header Referrer-Policy "strict-origin-when-cross-origin" always;

     # Cloudflare real IPs
     set_real_ip_from 103.21.244.0/22;
     ...
     real_ip_header CF-Connecting-IP;

     location /api/ {
       proxy_pass http://backend:8000/;
       proxy_set_header Host $host;
       proxy_set_header X-Forwarded-Proto $scheme;
       add_header 'Access-Control-Allow-Origin' 'https://bstock.ashreef.com' always;
       add_header 'Access-Control-Allow-Headers' 'Content-Type,Authorization,Accept,Origin';
     }
     ```
   - Optional: dedicate `api.bstock.ashreef.com` to the backend container and update CORS.

3. **Validation**
   ```bash
   nslookup bstock.ashreef.com
   curl -I https://bstock.ashreef.com
   docker-compose -f docker-compose.prod.yml ps
   docker-compose -f docker-compose.prod.yml exec frontend curl -f http://backend:8000/health
   ```

---

## 4. Backend PaaS Targets

### Render (Recommended)

- Root: repository root (Render can work with `render.yaml`)
- Build: `pip install -r backend/requirements.txt`
- Start: `cd backend && gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4`
- Environment: set `ENVIRONMENT=production`, `SECRET_KEY`, `DATABASE_URL`, `DISABLE_OPENAPI=true`, `AUTO_CREATE_TABLES=false`

### Heroku

```bash
heroku create your-bstock-backend
heroku addons:create heroku-postgresql:mini
heroku config:set ENVIRONMENT=production SECRET_KEY=... DISABLE_OPENAPI=true AUTO_CREATE_TABLES=false CORS_ALLOW_ORIGINS=https://your-frontend.vercel.app
git subtree push --prefix=backend heroku main
```

### Railway

1. Connect GitHub repo, point to `backend/`
2. Railway injects `PORT` and `DATABASE_URL`
3. Add remaining env vars via dashboard

### DigitalOcean App Platform

- Component: Web Service
- Source dir: `/backend`
- Build: `pip install -r requirements.txt`
- Run: `gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4`
- Attach DO-managed PostgreSQL and map `DATABASE_URL`

---

## 5. Frontend Hosting (Flutter Web)

### Vercel (Automated)

1. Import repo, set root to `frontend/`
2. `vercel.json` already references `vercel-flutter@0.2.0`
3. Deploy via dashboard or:
   ```bash
   cd frontend
   vercel --prod
   ```
4. Update backend CORS with the Vercel URL(s)
5. Override API targets in Flutter builds as needed:
   ```bash
   flutter run --dart-define=FLUTTER_DEVICE_API_URL=https://bstockapi.ashreef.com
   ```

### Other Static Hosts

- Run `build_flutter.sh` (see below) to generate `frontend/build/web`
- Upload to Netlify, Firebase Hosting, GitHub Pages, AWS S3, etc.
- Ensure SPA rewrites route every path back to `index.html`

---

## 6. Automated Build Script (`build_flutter.sh`)

What it does:
1. Clones Flutter SDK (`stable`) to `/tmp/flutter`
2. Runs `flutter config --no-analytics` and `flutter precache`
3. Executes `flutter pub get` + `flutter build web --release` inside `frontend/`

Usage examples:

```yaml
# GitHub Actions
- name: Build Flutter Web
  run: |
    chmod +x build_flutter.sh
    ./build_flutter.sh
```

```toml
# Netlify
[build]
  command = "./build_flutter.sh"
  publish = "frontend/build/web"
```

```bash
# Manual server build
chmod +x build_flutter.sh
./build_flutter.sh
# => frontend/build/web contains the deployable assets
```

Troubleshooting tips:
- Add execute permission (`chmod +x build_flutter.sh`)
- Ensure `git` is available for the Flutter clone
- Clean `/tmp/flutter` if you hit disk issues

---

## 7. Monitoring & Troubleshooting

```bash
# Health endpoints
curl http://localhost:8000/health
curl http://localhost:3000/health

# Container stats
docker stats

# Network inspection
docker network inspect npm-network

# SSL check
echo | openssl s_client -servername bstock.ashreef.com -connect bstock.ashreef.com:443 \
  2>/dev/null | openssl x509 -noout -dates
```

**Common fixes**
- 502 via NPM → check `docker-compose ... ps` and container logs
- CORS errors → confirm `.env` origins, redeploy backend, verify proxy headers
- Database issues → `docker-compose ... exec db pg_isready -U bstock_user`
- Slow builds on Vercel → first build downloads Flutter; subsequent builds cache artifacts

---

Need more context? See `README.md` for high-level project info and `BRAND_IDENTITY.md`
for the visual system that drives splash screens, icons, and marketing collateral.

