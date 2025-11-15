# BstocK Complete Deployment Guide

This comprehensive guide covers deploying both the backend (FastAPI) and frontend (Flutter) of the BstocK multi-tenant POS system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Backend Deployment](#backend-deployment)
  - [Environment Configuration](#environment-configuration)
  - [Render.com Deployment](#rendercom-deployment)
  - [Railway Deployment](#railway-deployment)
  - [Heroku Deployment](#heroku-deployment)
  - [DigitalOcean App Platform](#digitalocean-app-platform)
  - [Docker Deployment](#docker-deployment)
- [Frontend Deployment](#frontend-deployment)
  - [Vercel Deployment](#vercel-deployment-recommended)
  - [Netlify Deployment](#netlify-deployment)
  - [Firebase Hosting](#firebase-hosting)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Testing Your Deployment](#testing-your-deployment)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts
- GitHub account (for repository hosting)
- Backend hosting account (Render, Railway, Heroku, etc.)
- Frontend hosting account (Vercel, Netlify, etc.)

### Required Tools (for local testing)
- Python 3.8+ (for backend)
- Flutter SDK 3.4.3+ (for frontend)
- Git
- PostgreSQL (for production database)

---

## Backend Deployment

### Environment Configuration

Before deploying, you need to configure environment variables. All backend platforms require these variables:

#### Required Environment Variables

```bash
# Environment Type
ENVIRONMENT=production

# Security (CRITICAL - Generate a secure key!)
# Generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
SECRET_KEY=your-super-secure-secret-key-here

# Database Connection
DATABASE_URL=postgresql://user:password@host:port/dbname

# CORS Configuration (Replace with your frontend URL)
CORS_ALLOW_ORIGINS=https://your-app.vercel.app

# API Documentation (Disable in production for security)
DISABLE_OPENAPI=true

# Database Tables (Use migrations in production)
AUTO_CREATE_TABLES=false
```

#### Optional Environment Variables

```bash
# JWT Configuration
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS Details
CORS_ALLOW_CREDENTIALS=false
CORS_ALLOW_METHODS=GET,POST,PUT,DELETE,OPTIONS,PATCH
CORS_ALLOW_HEADERS=Content-Type,Authorization,Accept,Origin,User-Agent

# Server Configuration (usually auto-configured by hosting platform)
HOST=0.0.0.0
PORT=8000
```

---

### Render.com Deployment

**Render** is the recommended platform for backend deployment due to its simplicity and free tier.

#### Option 1: Infrastructure as Code (Recommended)

1. **Use the included `render.yaml` file**:
   - The file is already configured in `/backend/render.yaml`
   - Connect your GitHub repository to Render
   - Render will automatically detect and deploy

2. **Update CORS configuration**:
   - Edit `render.yaml` and update `CORS_ALLOW_ORIGINS` with your Vercel frontend URL

#### Option 2: Manual Dashboard Setup

1. **Create a new Web Service** on [render.com](https://render.com)

2. **Connect GitHub repository**

3. **Configure build settings**:
   ```
   Environment: Python
   Build Command: pip install -r backend/requirements.txt
   Start Command: cd backend && gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4
   ```

4. **Add a PostgreSQL database**:
   - Create a new PostgreSQL instance
   - Link it to your web service
   - Database URL will be automatically set

5. **Set environment variables** (see Environment Configuration above)

6. **Deploy!**
   - Your backend will be available at `https://your-app.onrender.com`

---

### Railway Deployment

1. **Connect repository** to [Railway](https://railway.app)

2. **Add PostgreSQL database**:
   - Railway automatically provides `DATABASE_URL`

3. **Set environment variables** in the Railway dashboard

4. **Railway auto-detects** your Procfile and deploys

5. **Your backend URL**: `https://your-app.railway.app`

---

### Heroku Deployment

1. **Install Heroku CLI** and login:
   ```bash
   heroku login
   ```

2. **Create app**:
   ```bash
   heroku create your-bstock-backend
   ```

3. **Add PostgreSQL**:
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. **Set environment variables**:
   ```bash
   heroku config:set ENVIRONMENT=production
   heroku config:set SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
   heroku config:set DISABLE_OPENAPI=true
   heroku config:set AUTO_CREATE_TABLES=false
   heroku config:set CORS_ALLOW_ORIGINS=https://your-app.vercel.app
   ```

5. **Deploy**:
   ```bash
   git subtree push --prefix=backend heroku main
   ```

---

### DigitalOcean App Platform

1. **Create new app** on [DigitalOcean](https://cloud.digitalocean.com/apps)

2. **Configure component**:
   ```
   Type: Web Service
   Source: GitHub repository
   Source Directory: /backend
   Build Command: pip install -r requirements.txt
   Run Command: gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4
   ```

3. **Add PostgreSQL database** component

4. **Set environment variables**

5. **Deploy**

---

### Docker Deployment

#### Using Docker Compose (Recommended for Self-Hosting)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/BstocK.git
   cd BstocK
   ```

2. **Create `.env` file** in the project root:
   ```bash
   cp backend/env.example .env
   # Edit .env with your configuration
   ```

3. **Generate a secure SECRET_KEY**:
   ```bash
   python -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))" >> .env
   ```

4. **Start services**:
   ```bash
   docker-compose up -d
   ```

5. **Access the backend**:
   - API: `http://localhost:8000`
   - API Docs: `http://localhost:8000/docs`

#### Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up -d --build
```

---

## Frontend Deployment

### Vercel Deployment (Recommended)

**Vercel** provides the easiest Flutter web deployment experience.

#### Prerequisites

The frontend already includes:
- `vercel.json` - Vercel configuration
- `.vercelignore` - Files to exclude from deployment

#### Deployment Steps

1. **Visit [vercel.com](https://vercel.com)** and sign in with GitHub

2. **Import your project**:
   - Click "New Project"
   - Select your `BstocK` repository
   - **Important**: Set root directory to `frontend/`

3. **Configure project**:
   ```
   Framework Preset: Other
   Root Directory: frontend/
   Build Command: (leave empty)
   Output Directory: (leave empty)
   Install Command: (leave empty)
   ```

4. **Deploy**:
   - Vercel automatically installs Flutter, builds, and deploys
   - Your app will be at: `https://your-app.vercel.app`

5. **Update API URL**:
   - Go to Project Settings → Environment Variables
   - Add: `FLUTTER_WEB_API_URL` = `https://your-backend.onrender.com`
   - Redeploy

#### Vercel CLI Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Navigate to frontend
cd frontend

# Deploy
vercel --prod
```

---

### Netlify Deployment

1. **Create `netlify.toml`** in frontend directory:
   ```toml
   [build]
     command = "flutter build web --release"
     publish = "build/web"
   
   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

2. **Connect repository** to [Netlify](https://netlify.com)

3. **Configure build**:
   - Build command: `flutter build web --release`
   - Publish directory: `build/web`

4. **Add environment variable**:
   - `FLUTTER_WEB_API_URL` = Your backend URL

5. **Deploy**

---

### Firebase Hosting

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase**:
   ```bash
   cd frontend
   firebase init hosting
   ```

3. **Configure `firebase.json`**:
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
       "rewrites": [{
         "source": "**",
         "destination": "/index.html"
       }]
     }
   }
   ```

4. **Build Flutter app**:
   ```bash
   flutter build web --release
   ```

5. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

---

## Post-Deployment Configuration

### 1. Update Backend CORS

After deploying frontend, update backend CORS configuration:

**For Render/Railway/Heroku:**
- Update environment variable: `CORS_ALLOW_ORIGINS=https://your-frontend.vercel.app`
- Restart the backend service

### 2. Update Frontend API URL

**Option A: Environment Variable (Recommended)**
- In Vercel/Netlify dashboard, add: `FLUTTER_WEB_API_URL=https://your-backend.onrender.com`

**Option B: Code Change**
- Edit `frontend/lib/api/api_service.dart`:
  ```dart
  static const String apiUrl = 'https://your-backend.onrender.com';
  ```

### 3. Database Migration

For production, use proper database migrations:

```bash
# Install Alembic
pip install alembic

# Initialize migrations
alembic init migrations

# Create migration
alembic revision --autogenerate -m "Initial schema"

# Apply migration
alembic upgrade head
```

### 4. Test the Integration

1. Visit your frontend URL
2. Create an organization (onboarding)
3. Add products
4. Make a test sale
5. Generate a PDF receipt
6. Check analytics

---

## Testing Your Deployment

### Backend Health Checks

```bash
# Basic health check
curl https://your-backend.onrender.com/healthz

# Should return: {"status":"ok","env":"production"}
```

### Frontend Tests

1. **Load the app**: Visit your frontend URL
2. **Check API connection**: Try logging in
3. **Test CORS**: Open browser console, verify no CORS errors
4. **Test features**:
   - Create organization
   - Add products
   - Process sale
   - Generate receipt

### Common Issues

**CORS Errors**:
- Verify `CORS_ALLOW_ORIGINS` matches frontend URL exactly
- Check for trailing slashes (include or exclude consistently)
- Ensure HTTPS is used in production

**Database Connection Errors**:
- Verify `DATABASE_URL` is correct
- Check database is running and accessible
- Verify database credentials

**Frontend Can't Connect**:
- Check `FLUTTER_WEB_API_URL` environment variable
- Verify backend is running
- Check browser console for errors

---

## Troubleshooting

### Backend Issues

#### Application Won't Start

```bash
# Check logs
# Render: Dashboard → Logs tab
# Railway: Dashboard → Deployments → View logs
# Heroku: heroku logs --tail
# Docker: docker-compose logs -f backend
```

**Common causes**:
- Missing `SECRET_KEY` environment variable
- Invalid `DATABASE_URL`
- Python version mismatch
- Missing dependencies

#### 502/503 Errors

**Causes**:
- App not binding to correct port
- App crashed during startup
- Health check failing

**Solutions**:
- Verify Procfile command is correct
- Check app binds to `0.0.0.0:$PORT`
- Review application logs

#### CORS Errors

**Solutions**:
- Update `CORS_ALLOW_ORIGINS` with exact frontend URL
- Remove trailing slashes from URLs
- Verify environment variables are set correctly

### Frontend Issues

#### Build Fails

**Common causes**:
- Flutter version incompatibility
- Missing dependencies
- Syntax errors in Dart code

**Solutions**:
- Check Flutter version in `pubspec.yaml`
- Run `flutter pub get` locally
- Run `flutter analyze` to check for errors

#### Blank Page After Deployment

**Causes**:
- API connection failed
- JavaScript errors
- Incorrect base URL

**Solutions**:
- Open browser console (F12)
- Check for API connection errors
- Verify `FLUTTER_WEB_API_URL` is set correctly

#### Routing Issues (404 on Refresh)

**Cause**: Server not configured for SPA routing

**Solutions**:
- Vercel: `vercel.json` already configured
- Netlify: Add `_redirects` file or use `netlify.toml`
- Firebase: Configured in `firebase.json`

---

## Security Checklist

Before going to production:

- [ ] Generate and set a secure `SECRET_KEY`
- [ ] Use PostgreSQL (not SQLite) for database
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `DISABLE_OPENAPI=true` (hide API docs)
- [ ] Set `AUTO_CREATE_TABLES=false` (use migrations)
- [ ] Configure proper CORS origins (not `*`)
- [ ] Use HTTPS for both frontend and backend
- [ ] Enable database backups
- [ ] Set up monitoring and alerts
- [ ] Review and limit database user permissions

---

## Monitoring and Maintenance

### Recommended Tools

**Backend Monitoring**:
- **Sentry** - Error tracking
- **Uptime Robot** - Uptime monitoring
- **LogDNA** - Log aggregation

**Database**:
- Regular backups (daily recommended)
- Monitor connection pool usage
- Set up slow query logging

**Frontend**:
- **Vercel Analytics** - User analytics
- **Google Analytics** - Traffic analysis
- **LogRocket** - Session replay and debugging

### Regular Maintenance

**Weekly**:
- Review error logs
- Check database size and backups
- Monitor API response times

**Monthly**:
- Review and update dependencies
- Check for security updates
- Review and optimize slow queries

**Quarterly**:
- Load testing
- Security audit
- Disaster recovery testing

---

## Scaling Considerations

### When to Scale

Scale when you experience:
- Slow API response times (>500ms average)
- High CPU usage (>70% sustained)
- Database connection pool exhaustion
- Memory pressure

### Scaling Strategies

**Backend**:
1. **Vertical scaling**: Increase server resources
2. **Horizontal scaling**: Add more workers/instances
3. **Database scaling**: 
   - Add read replicas
   - Implement connection pooling
   - Add caching layer (Redis)

**Frontend**:
- Vercel/Netlify handle scaling automatically
- Use CDN for assets
- Implement lazy loading

---

## Cost Estimates

### Free Tier Deployments

**Backend** (Render Free Tier):
- Cost: $0/month
- Limitations: Sleeps after 15 min inactivity, 750 hours/month

**Frontend** (Vercel Free Tier):
- Cost: $0/month
- Limitations: 100GB bandwidth, unlimited sites

**Total**: $0/month (suitable for testing and small deployments)

### Production Deployments

**Backend** (Render Starter):
- Cost: $7/month
- Features: No sleep, 1 vCPU, 512MB RAM

**Database** (Render PostgreSQL):
- Cost: $7/month
- Features: 1GB storage, 60 connection limit

**Frontend** (Vercel Pro):
- Cost: $20/month
- Features: Unlimited bandwidth, priority support

**Total**: ~$34/month (suitable for small businesses)

---

## Next Steps

After successful deployment:

1. **Set up a custom domain**:
   - Backend: Configure DNS in hosting provider
   - Frontend: Add custom domain in Vercel/Netlify

2. **Configure email notifications** (future feature)

3. **Set up analytics tracking**

4. **Create user documentation**

5. **Plan for backups and disaster recovery**

6. **Set up CI/CD pipeline** for automatic deployments

---

## Support and Resources

### Documentation Links
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Web Documentation](https://docs.flutter.dev/deployment/web)
- [Render Documentation](https://render.com/docs)
- [Vercel Documentation](https://vercel.com/docs)

### Getting Help
- Check application logs first
- Review this deployment guide
- Search existing GitHub issues
- Create a new issue with:
  - Deployment platform
  - Error messages
  - Steps to reproduce

---

**Congratulations!** You now have a fully deployed multi-tenant POS system. 🎉

For questions or issues, please refer to the main README.md or create an issue on GitHub.

---

*Last Updated: November 2025*
*BstocK Version: 2.0.0*
