# BstocK Backend Deployment Guide

## 🚀 Deploying to PaaS Platforms

This backend is ready for deployment on various Platform-as-a-Service (PaaS) providers.

### ✅ Pre-deployment Checklist

- [x] Environment variables configured
- [x] Requirements.txt with locked dependencies
- [x] Procfile for production server
- [x] CORS configured for your frontend
- [x] Database ready (PostgreSQL recommended for production)

---

## 🎯 Render.com Deployment

### Option 1: Manual Deployment via Dashboard

1. **Create a new Web Service** on [Render](https://render.com)
2. **Connect your GitHub repository**
3. **Configure the service:**
   - **Environment**: `Python`
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `cd backend && gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4`
   - **Root Directory**: Leave empty (or set to `backend` if you want to deploy only the backend)

4. **Set Environment Variables:**
   ```
   ENVIRONMENT=production
   SECRET_KEY=your-super-secure-secret-key-here
   DATABASE_URL=your-postgresql-connection-string
   DISABLE_OPENAPI=true
   AUTO_CREATE_TABLES=false
   CORS_ALLOW_ORIGINS=https://your-vercel-app.vercel.app
   ```

5. **Create a PostgreSQL Database** and link it to your service

### Option 2: Infrastructure as Code

Use the included `render.yaml` file for automated deployment:

1. Place `render.yaml` in your repository root
2. Connect your GitHub repo to Render
3. Render will automatically deploy based on the configuration

---

## 🔥 Heroku Deployment

1. **Install Heroku CLI** and login: `heroku login`

2. **Create a new app:**
   ```bash
   heroku create your-bstock-backend
   ```

3. **Add PostgreSQL addon:**
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. **Set environment variables:**
   ```bash
   heroku config:set ENVIRONMENT=production
   heroku config:set SECRET_KEY=your-super-secure-secret-key
   heroku config:set DISABLE_OPENAPI=true
   heroku config:set AUTO_CREATE_TABLES=false
   heroku config:set CORS_ALLOW_ORIGINS=https://your-vercel-app.vercel.app
   ```

5. **Deploy:**
   ```bash
   git subtree push --prefix=backend heroku main
   ```

---

## 🌊 Railway Deployment

1. **Connect your GitHub repository** to [Railway](https://railway.app)

2. **Set environment variables:**
   - Railway will automatically provide `DATABASE_URL` and `PORT`
   - Add your other environment variables in the Railway dashboard

3. **Railway will automatically detect** your Procfile and deploy

---

## ⚡ DigitalOcean App Platform

1. **Create a new app** on [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)

2. **Configure the component:**
   - **Type**: Web Service
   - **Source**: Your GitHub repository
   - **Source Directory**: `/backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Run Command**: `gunicorn app.main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT --workers 4`

3. **Add a PostgreSQL database** component

4. **Set environment variables** in the app settings

---

## 🛠️ Environment Variables Reference

### Required for Production:
```bash
ENVIRONMENT=production
SECRET_KEY=your-super-secure-secret-key-here
DATABASE_URL=postgresql://user:pass@host:port/dbname
```

### CORS Configuration:
```bash
CORS_ALLOW_ORIGINS=https://your-vercel-app.vercel.app
CORS_ALLOW_CREDENTIALS=false
CORS_ALLOW_METHODS=GET,POST,PUT,DELETE,OPTIONS,PATCH
CORS_ALLOW_HEADERS=Content-Type,Authorization,Accept,Origin,User-Agent
```

### Optional:
```bash
DISABLE_OPENAPI=true          # Hide API docs in production
AUTO_CREATE_TABLES=false      # Use migrations in production
HOST=0.0.0.0                  # Usually auto-configured by PaaS
PORT=8000                     # Usually auto-configured by PaaS
```

---

## 🔧 Database Setup

### For Development:
- SQLite (default): No additional setup needed

### For Production:
- PostgreSQL (recommended): Use your PaaS provider's database service
- Set `AUTO_CREATE_TABLES=false` and use proper migrations

---

## 🧪 Testing Your Deployment

1. **Health Check**: `GET https://your-app.com/healthz`
2. **API Docs**: `GET https://your-app.com/docs` (if enabled)
3. **CORS Test**: Make a request from your Flutter web app

---

## 🆘 Troubleshooting

### Common Issues:

**1. Application not starting:**
- Check your `SECRET_KEY` is set
- Verify `DATABASE_URL` is correct
- Check logs for Python/dependency errors

**2. CORS errors:**
- Verify `CORS_ALLOW_ORIGINS` matches your frontend URL exactly
- Check that your frontend is using HTTPS in production

**3. Database connection issues:**
- Ensure your DATABASE_URL is correct
- Check if your database is accessible from the app
- Verify database credentials

**4. 502/503 errors:**
- Check if your app is binding to `0.0.0.0:$PORT`
- Verify the Procfile command is correct
- Check application logs for startup errors

---

## 📚 Next Steps

1. **Set up monitoring** with your PaaS provider
2. **Configure custom domain** for your API
3. **Set up CI/CD** for automatic deployments
4. **Add database migrations** for schema changes
5. **Configure logging** for production debugging

Happy deploying! 🎉
