# Flutter Web Deployment to Vercel

## 🚀 Quick Setup Guide

Your Flutter app is now configured to deploy to Vercel using the `vercel-flutter` community runtime.

### 📁 Configuration Files Created

#### `vercel.json`
```json
{
  "version": 2,
  "builds": [
    {
      "src": "pubspec.yaml",
      "use": "vercel-flutter@0.2.0"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "github": {
    "silent": true
  }
}
```

#### `.vercelignore`
Excludes unnecessary files from deployment to speed up builds.

### 🔧 Deployment Steps

#### Option 1: Vercel Dashboard (Recommended)

1. **Visit [vercel.com](https://vercel.com)** and sign in with your GitHub account

2. **Import your project:**
   - Click "New Project"
   - Select your `BstocK` repository
   - **Important:** Set the root directory to `frontend/`

3. **Configure project settings:**
   ```
   Framework Preset: Other
   Root Directory: frontend/
   Build Command: (leave empty - handled by vercel.json)
   Output Directory: (leave empty - handled by vercel.json)
   Install Command: (leave empty - handled by vercel.json)
   ```

4. **Deploy!** Vercel will automatically:
   - Install Flutter SDK
   - Run `flutter pub get`
   - Build your app with `flutter build web`
   - Deploy to a URL like `https://your-app-name.vercel.app`

#### Option 2: Vercel CLI

```bash
# Install Vercel CLI
npm i -g vercel

# Navigate to frontend directory
cd frontend

# Deploy
vercel --prod
```

### 🔗 Backend Integration

Once deployed, update your backend CORS configuration:

1. **Get your Vercel URL** (e.g., `https://bstock-app.vercel.app`)

2. **Update your backend environment variables:**
   ```bash
   CORS_ALLOW_ORIGINS=https://your-vercel-app-url.vercel.app
   ```

3. **For multiple environments:**
   ```bash
   CORS_ALLOW_ORIGINS=https://bstock-app.vercel.app,https://bstock-app-staging.vercel.app
   ```

### 🎯 Flutter App API Configuration

Update your Flutter app to point to your deployed backend:

**In `lib/api/api_service.dart`:**
```dart
class ApiService {
  // Replace with your deployed backend URL
  static const String baseUrl = 'https://your-backend-on-render.com';
  
  // ... rest of your API service
}
```

### 🔍 Troubleshooting

#### Common Issues:

**1. Build Fails with "Flutter not found"**
- Solution: The `vercel-flutter@0.2.0` runtime handles this automatically

**2. App loads but API calls fail**
- Check CORS configuration on your backend
- Verify the API base URL in your Flutter app
- Check browser console for CORS errors

**3. Routing issues (404 on refresh)**
- The `vercel.json` routes configuration handles this with SPA fallback

**4. Build times are slow**
- This is normal for Flutter web builds (2-5 minutes)
- Subsequent builds are faster due to caching

### 📋 Environment Variables

If your Flutter app needs environment variables:

1. **In Vercel Dashboard:**
   - Go to Project Settings → Environment Variables
   - Add variables like `API_BASE_URL`

2. **In your Flutter app:**
   ```dart
   // Use const values or compile-time constants
   static const String apiBaseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://your-backend.com',
   );
   ```

### 🎉 Success!

Once deployed, your Flutter web app will be available at:
`https://your-project-name.vercel.app`

**Next Steps:**
1. Test your deployed app
2. Configure custom domain (optional)
3. Set up preview deployments for staging
4. Monitor performance with Vercel Analytics

### 📚 Additional Resources

- [Vercel Flutter Runtime Documentation](https://github.com/mrtnetwork/vercel-flutter)
- [Flutter Web Deployment Guide](https://docs.flutter.dev/deployment/web)
- [Vercel Documentation](https://vercel.com/docs)

---

**Need help?** Check the Vercel deployment logs for detailed error messages.
