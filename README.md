# BstocK - Multi-Tenant POS & Business Management System

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white" alt="Render" />
</div>

## 📋 Overview

BstocK is a comprehensive multi-tenant Point of Sale (POS) and business management platform designed for small to medium-sized businesses with minimal digital literacy. Built with a focus on simplicity and usability, it provides inventory management, sales tracking, analytics, and offline functionality - all wrapped in an intuitive interface that anyone can use.

## ✨ Core Philosophy: The Simplicity Manifesto

- **Simple by Default, Powerful on Demand**: Complex features are hidden behind optional menus using progressive disclosure
- **The One-Thumb Checkout**: POS interface designed for speed and efficiency
- **Clarity and Forgiveness**: Clear language, predictable UI, and confirmations for destructive actions
- **Offline First**: Sales transactions work without an internet connection

## 🚀 Key Features

### 🏪 Multi-Tenant Architecture
- Complete data isolation between businesses
- Each organization has its own products, customers, sales, and users
- Secure role-based access control (Owner/Cashier)

### 💰 Point of Sale (POS)
- Fast, touch-optimized checkout interface
- Barcode scanning for quick product lookup
- Multiple payment methods (cash, card, mobile, bank transfer)
- Real-time inventory updates
- Digital receipt generation and sharing via PDF

### 📦 Inventory Management
- Product variants (e.g., T-Shirt in different sizes and colors)
- SKU and barcode support
- Purchase and sale price tracking
- Low stock alerts
- Category management

### 📊 Analytics & Reporting
- Sales revenue and profit tracking
- Best-selling products analysis
- Date-range filtering
- Customer purchase history

### 📱 Mobile-First Design
- Flutter cross-platform application
- Responsive web interface
- Offline sales with automatic sync
- Native sharing for receipts

### 👥 User Management
- Organization owners can create and manage cashier accounts
- Role-based permissions
- Activity tracking

## 🛠️ Technology Stack

### Frontend
- **Flutter** - Cross-platform mobile and web framework
- **Dart** - Programming language
- **Provider** - State management
- **Go Router** - Navigation
- **sqflite/isar** - Local database for offline functionality
- **share_plus** - Native sharing for receipts

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - Database ORM with multi-tenant support
- **Pydantic** - Data validation
- **JWT** - Token-based authentication
- **ReportLab** - PDF generation for receipts
- **WebSockets** - Real-time notifications

### Database
- **PostgreSQL** - Production database
- **SQLite** - Development database
- Full support for JSON fields for flexible product attributes

## 🏗️ Project Structure

```
BstocK/
├── frontend/                  # Flutter application
│   ├── lib/
│   │   ├── api/              # API service layer
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management
│   │   ├── screens/
│   │   │   ├── onboarding/   # New organization setup
│   │   │   ├── pos/          # POS checkout interface
│   │   │   ├── inventory/    # Product management
│   │   │   ├── analytics/    # Sales reports
│   │   │   └── settings/     # Configuration
│   │   ├── widgets/          # Reusable components
│   │   └── router/           # Navigation configuration
│   └── pubspec.yaml          # Dependencies
│
├── backend/                   # FastAPI application
│   ├── app/
│   │   ├── routers/
│   │   │   ├── auth.py       # Authentication & onboarding
│   │   │   ├── products.py   # Product & variant management
│   │   │   ├── pos.py        # POS sales transactions
│   │   │   ├── receipts.py   # PDF receipt generation
│   │   │   ├── analytics.py  # Business analytics
│   │   │   └── users.py      # User management
│   │   ├── models.py         # Database models
│   │   ├── schemas.py        # Pydantic schemas
│   │   ├── crud.py           # Database operations
│   │   ├── auth.py           # Authentication logic
│   │   ├── database.py       # Database configuration
│   │   └── main.py           # Application entry point
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Container configuration
│
└── docker-compose.yml        # Multi-service orchestration
```

## 🚦 Getting Started

### Prerequisites
- **Flutter SDK** (>= 3.4.3)
- **Python** (>= 3.8)
- **PostgreSQL** (for production)
- **Docker** (optional)

### Backend Setup

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

5. Start the development server:
   ```bash
   uvicorn app.main:app --reload
   ```

   The API will be available at `http://localhost:8000`
   API documentation: `http://localhost:8000/docs`

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd ../frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter application:
   ```bash
   flutter run
   ```

## 📱 User Workflows

### First-Time Setup (Onboarding)
1. User opens the app
2. Guided wizard collects:
   - Organization name
   - Owner username and password
3. Account is created automatically
4. User is taken to a simple tutorial for adding first product

### Owner Workflow
- Full access to all features via bottom navigation:
  - **POS**: Process sales
  - **Inventory**: Manage products and variants
  - **Analytics**: View sales reports
  - **Settings**: Manage users and organization settings

### Cashier Workflow
- Direct access to POS screen after login
- Limited navigation (POS screen only)
- Can process sales and view inventory
- Cannot modify products or access analytics

### POS Transaction Flow
1. Cashier opens POS screen
2. Scans barcode or selects product from grid
3. Adjusts quantity if needed
4. Taps "Charge" button
5. Selects payment method
6. Sale is completed
7. Option to share receipt via any app (WhatsApp, email, etc.)

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/onboarding` - Create new organization
- `POST /api/auth/token` - Login
- `GET /api/auth/me` - Get current user

### Products
- `POST /api/products` - Create product with variants
- `GET /api/products` - List products
- `GET /api/products/{id}` - Get product details
- `PUT /api/products/{id}` - Update product
- `POST /api/products/{id}/variants` - Add variant
- `PUT /api/products/variants/{id}` - Update variant

### POS
- `POST /api/pos/sales` - Create sale (atomic transaction)
- `GET /api/pos/sales` - List sales
- `GET /api/pos/sales/{id}` - Get sale details

### Receipts
- `GET /api/receipts/{sale_id}/pdf` - Download PDF receipt

### Analytics
- `GET /api/analytics/summary` - Get sales analytics (with date filtering)

### Users
- `GET /api/users` - List organization users
- `POST /api/users` - Create user
- `PATCH /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user

## 🗄️ Database Schema

### Key Models

**Organization**
- Multi-tenant root entity
- Has owner, products, sales, users

**User**
- Belongs to one organization
- Role: owner or cashier

**Product**
- Base product (e.g., "T-Shirt")
- Has multiple variants

**Variant**
- Specific sellable item with SKU, barcode
- Attributes (JSON): size, color, etc.
- Pricing and inventory

**Sale**
- Complete transaction record
- Payment method, totals, profit

**SaleItem**
- Individual items in a sale
- Records price at time of sale

## 🔒 Security

- JWT-based authentication with organization_id in token
- All database queries scoped to authenticated user's organization
- Password hashing with bcrypt
- Role-based access control
- CORS protection
- SQL injection prevention

## 📈 Performance

- Optimized database queries with eager loading
- Indexed fields for fast lookups
- Decimal precision for financial calculations
- Efficient state management in Flutter
- Offline support with local database
- Automatic background sync

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

## 🚀 Deployment

### Backend (Render/Railway/Fly.io)
1. Connect repository
2. Set environment variables
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### Frontend
- **Web**: Deploy to Vercel/Netlify
- **Mobile**: Build APK/IPA and distribute

## 🎯 Roadmap

- [x] Multi-tenant architecture
- [x] Product variants
- [x] POS system
- [x] PDF receipts
- [x] Analytics
- [ ] Customer management
- [ ] Vendor management
- [ ] Purchase orders
- [ ] Inventory adjustments
- [ ] Multi-currency support
- [ ] Tax calculation
- [ ] Loyalty programs
- [ ] Employee commission tracking

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

For questions or issues:
- Create an issue on GitHub
- Check API documentation at `/docs` endpoint

---

<div align="center">
  <p>Built with ❤️ for small businesses everywhere</p>
  <p>© 2024 BstocK. All rights reserved.</p>
</div>
