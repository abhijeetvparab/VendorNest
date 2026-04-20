# VendorNest — Python FastAPI Backend

## Stack
- **FastAPI** — REST API framework
- **MySQL** — database
- **SQLAlchemy** — ORM
- **JWT** — authentication (access + refresh tokens)
- **bcrypt** — password hashing

## Setup

### 1. Create MySQL database
```sql
CREATE DATABASE vendornest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your MySQL credentials and a strong SECRET_KEY
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Create tables & seed data
```bash
python init_db.py
```

### 5. Run the server
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at: **http://localhost:8000/docs**

## Demo Credentials
| Role     | Email                       | Password   |
|----------|-----------------------------|------------|
| Admin    | admin@vendornest.com         | admin123   |
| Vendor   | vendor@vendornest.com        | vendor123  |
| Customer | customer@vendornest.com      | cust123    |

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
