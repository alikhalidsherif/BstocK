# BstocK - Inventory Management System

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white" alt="Render" />
  <img src="https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" alt="Vercel" />
</div>

## 📋 Overview

BstocK is a comprehensive inventory management system designed for modern businesses. Built with cutting-edge technologies, it provides real-time inventory tracking, user management, and seamless mobile/web access for efficient stock operations.

## 🚀 Live Demo

- **Backend API (Primary):** [https://bstockapi.ashreef.com](https://bstockapi.ashreef.com)
- **Backend API (Failover):** [https://bstock-bv2k.onrender.com](https://bstock-bv2k.onrender.com)
- **Frontend (Primary):** [https://bstock.ashreef.com](https://bstock.ashreef.com)
- **Frontend (Failover):** [https://bstock-ashy.vercel.app](https://bstock-ashy.vercel.app)
- **API Documentation:** [https://bstock-bv2k.onrender.com/docs](https://bstock-bv2k.onrender.com/docs)

## ✨ Features

### 🔐 Authentication & Authorization
- Secure user authentication with JWT tokens
- Role-based access control (Admin/User roles)
- User management and permissions

### 📦 Inventory Management
- Add, edit, and remove products
- Real-time stock level tracking
- Barcode scanning for quick product lookup
- Product categorization and search

### 📊 Transaction Management
- Stock addition and sale requests
- Transaction history and audit trails
- Payment status tracking
- Approval workflows for stock changes

### 📱 Multi-Platform Support
- Flutter mobile application (Android/iOS)
- Responsive web interface
- Cross-platform synchronization

### 🔄 Real-time Features
- WebSocket connections for live updates
- Real-time notifications
- Instant inventory synchronization

## 🛠️ Technology Stack

### Frontend
- **Flutter** - Cross-platform mobile and web framework
- **Dart** - Programming language
- **Provider** - State management
- **Go Router** - Navigation and routing
- **Material Design 3** - UI/UX framework

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - Database ORM
- **Pydantic** - Data validation
- **JWT** - Authentication tokens
- **WebSockets** - Real-time communication

### Database
- **PostgreSQL** - Primary database (Production)
- **SQLite** - Development database
- **Neon** - Managed PostgreSQL hosting

### Deployment & Infrastructure
- **Render** - Backend hosting and deployment
- **Vercel** - Frontend web deployment (alternative)
- **Docker** - Containerization
- **GitHub Actions** - CI/CD pipeline

## 🏗️ Project Structure

```
BstocK/
├── frontend/                 # Flutter application
│   ├── lib/
│   │   ├── api/             # API service layer
│   │   ├── models/          # Data models
│   │   ├── providers/       # State management
│   │   ├── screens/         # UI screens
│   │   ├── widgets/         # Reusable components
│   │   └── router/          # Navigation configuration
│   ├── android/             # Android-specific files
│   ├── ios/                 # iOS-specific files
│   └── web/                 # Web-specific files
│
├── backend/                 # FastAPI application
│   ├── app/
│   │   ├── routers/         # API endpoints
│   │   ├── models.py        # Database models
│   │   ├── schemas.py       # Pydantic schemas
│   │   ├── database.py      # Database configuration
│   │   ├── auth.py          # Authentication logic
│   │   └── main.py          # Application entry point
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Container configuration
│
└── docker-compose.yml       # Multi-service orchestration
```

## 🚦 Getting Started

### Prerequisites
- **Flutter SDK** (>= 3.4.3)
- **Python** (>= 3.8)
- **PostgreSQL** (for production)
- **Docker** (optional, for containerized development)

### Local Development Setup

#### Backend Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/bstock.git
   cd BstocK/backend
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables:
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

5. Configure the master account (required). The values of `MASTER_USERNAME` and
   `MASTER_PASSWORD` in `.env` are used to auto-create a non-editable, non-deletable
   root user every time the API boots. Make sure you change the defaults before deploying.

6. Initialize the database (optional once the master account exists):
   ```bash
   # Set environment variables for admin user
   export ADMIN_USERNAME="admin"
   export ADMIN_PASSWORD="your-secure-password"
   
   # Run the seeding script
   python -m app.seed
   ```

7. Start the development server:
   ```bash
   uvicorn app.main:app --reload
   ```

### Automated database migrations

The backend now ships with Alembic migration scripts. Every time the API starts in a
non-SQLite environment it automatically runs `alembic upgrade head` to bring the schema
up to date (so existing data is preserved while new columns/constraints are applied).
For local SQLite development you can continue to rely on `AUTO_CREATE_TABLES=true`.

#### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd ../frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Update API configuration:
   - For Android: Update `android/app/src/main/AndroidManifest.xml` if you need custom permissions.
   - The production backend endpoints are `https://bstockapi.ashreef.com` (primary) and `https://bstock-bv2k.onrender.com` (failover). Use `--dart-define FLUTTER_DEVICE_API_URL=<url>` or `FLUTTER_WEB_API_URL=<url>` to target staging/local servers as needed.

4. Run the Flutter application:
   ```bash
   flutter run
   ```

### Docker Setup (Alternative)
```bash
# Build and run with Docker Compose
docker-compose up --build

# Access the application:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
```

## 📱 Mobile App Features

### For Users
- **Product Lookup**: Barcode scanning and search functionality
- **Stock Requests**: Submit requests for stock additions or sales
- **Transaction History**: View personal transaction records
- **Profile Management**: Update personal information

### For Administrators
- **User Management**: Create and manage user accounts
- **Product Management**: Add, edit, and archive products
- **Request Approval**: Review and approve stock change requests
- **Analytics Dashboard**: View comprehensive business insights
- **System Settings**: Configure application preferences

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```bash
# Database
DATABASE_URL=postgresql://username:password@host:port/database

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
CORS_ALLOW_ORIGINS=["https://your-frontend-domain.com"]

# Admin Seeding
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-secure-password

# Environment
ENVIRONMENT=production
```

#### Frontend (API Configuration)
Update the API base URL in your Flutter app to point to the production backend. By default the app targets `https://bstockapi.ashreef.com`, with an automatic fallback to `https://bstock-bv2k.onrender.com`. You can override this at build time:
```dart
// Example: use a local dev server when running the emulator
flutter run --dart-define=FLUTTER_DEVICE_API_URL=http://10.0.2.2:8000
```

## 🚀 Deployment

### Backend Deployment (Render)
1. Connect your GitHub repository to Render
2. Configure environment variables in Render dashboard
3. Set the build command: `pip install -r requirements.txt`
4. Set the start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### Frontend Deployment
The Flutter app can be deployed as:
- **Web App**: Using Vercel or Netlify
- **Mobile App**: Build APK/IPA and distribute via app stores
- **Progressive Web App**: With service workers for offline functionality

## 🧪 Testing

### Backend Tests
```bash
cd backend
python -m pytest
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## 📈 Performance & Security

### Security Features
- JWT-based authentication
- Password hashing with bcrypt
- CORS protection
- SQL injection prevention
- Input validation and sanitization

### Performance Optimizations
- Database query optimization
- Efficient state management
- Image compression and caching
- Lazy loading of data
- WebSocket connection pooling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the [API documentation](https://bstock-bv2k.onrender.com/docs)

## 🎯 Roadmap

- [ ] Advanced analytics and reporting
- [ ] Multi-warehouse support
- [ ] Integration with external accounting systems
- [ ] Mobile push notifications
- [ ] Offline functionality
- [ ] API rate limiting
- [ ] Advanced search and filtering
- [ ] Export/import functionality

---

<div align="center">
  <p>Built with ❤️ using Flutter and FastAPI</p>
  <p>© 2024 BstocK. All rights reserved.</p>
</div>