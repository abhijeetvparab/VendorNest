# VendorNest Setup Instructions

## Backend Setup

### Prerequisites
- **MySQL database** must be running
- Create the database:
  ```sql
  CREATE DATABASE vendornest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  ```
- Create `.env` file with MySQL credentials and `SECRET_KEY`

### Option 1: Monolithic (Simple)
```bash
cd backend
pip install -r requirements.txt
python init_db.py
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Option 2: Microservices (Recommended)
```bash
cd backend/user_management
pip install -r requirements.txt
python init_db.py
python start_all.py
```

**Services will run on:**
- Auth Service: `http://localhost:8001/docs`
- User Service: `http://localhost:8002/docs`
- Vendor Service: `http://localhost:8003/docs`
- API Gateway: `http://localhost:8000/docs`

### Demo Credentials
| Role     | Email                       | Password   |
|----------|-----------------------------|------------|
| Admin    | admin@vendornest.com         | admin123   |
| Vendor   | vendor@vendornest.com        | vendor123  |
| Customer | customer@vendornest.com      | cust123    |

## Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

You can also run on specific platforms:
```bash
flutter run -d chrome        # Web
flutter run -d android       # Android emulator/device
flutter run -d ios           # iOS simulator/device
```

**Note:** The frontend connects to the API via `api_config.dart` — update the base URL if needed.

## API Endpoints

### Authentication
| Method | Endpoint                    | Access      | Description              |
|--------|-----------------------------|-------------|--------------------------|
| POST   | /api/auth/register          | Public      | Register Vendor/Customer |
| POST   | /api/auth/login             | Public      | Login & receive JWT      |
| POST   | /api/auth/refresh           | Authenticated| Refresh access token    |
| POST   | /api/auth/forgot-password   | Public      | Send reset link (simulated) |

### Users
| Method | Endpoint                    | Access      | Description              |
|--------|-----------------------------|-------------|--------------------------|
| GET    | /api/users                  | Admin       | List all users (filtered)|
| GET    | /api/users/me               | Any         | Current user profile     |
| GET    | /api/users/{id}             | Admin/Self  | Get user by ID           |
| PUT    | /api/users/{id}             | Admin/Self  | Update user details      |
| DELETE | /api/users/{id}             | Admin       | Delete user              |
| PATCH  | /api/users/{id}/status      | Admin       | Activate/deactivate      |
| POST   | /api/users/admin            | Admin       | Create admin account     |

### Vendors
| Method | Endpoint                              | Access       | Description            |
|--------|---------------------------------------|--------------|------------------------|
| POST   | /api/vendors/onboarding               | Vendor       | Submit application     |
| GET    | /api/vendors/onboarding               | Admin        | List all applications  |
| GET    | /api/vendors/onboarding/mine          | Vendor       | Own application        |
| GET    | /api/vendors/onboarding/{id}          | Admin/Vendor | Application by ID      |
| PATCH  | /api/vendors/onboarding/{id}/approve  | Admin        | Approve vendor         |
| PATCH  | /api/vendors/onboarding/{id}/reject   | Admin        | Reject with reason     |
| GET    | /api/vendors/approved                 | Public       | Browse approved vendors|

## Stack Information
- **Backend:** FastAPI, MySQL, SQLAlchemy, JWT, bcrypt
- **Frontend:** Flutter