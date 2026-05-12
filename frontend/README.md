# E-Bill Flutter App
## Electricity Billing System — Mobile Frontend
**IT224 Systems Integration and Architecture | Final Performance Innovative Task**

---

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry + splash screen + routing
├── theme.dart                       # Colors, theme, design tokens
├── services/
│   ├── api_service.dart             # All HTTP calls to Laravel API
│   └── auth_service.dart            # Login session management
└── screens/
    ├── auth/
    │   ├── login_screen.dart        # Login (username + password)
    │   └── register_screen.dart     # New user registration
    ├── user/
    │   ├── user_main.dart           # Bottom nav shell
    │   ├── user_dashboard.dart      # Dashboard with bill summary
    │   ├── my_bills_screen.dart     # View + search bills
    │   ├── pay_bill_screen.dart     # Pay a bill (cash/gcash/maya/bank)
    │   └── profile_screen.dart      # View + edit profile
    └── admin/
        ├── admin_main.dart          # Bottom nav shell
        ├── admin_dashboard.dart     # Stats: revenue, users, bills
        ├── admin_bills_screen.dart  # View + search all bills
        ├── add_bill_screen.dart     # Add new bill for a customer
        └── admin_users_screen.dart  # View + search all customers
```

---

## ✅ Features Implemented

### Login Authentication
- Username + password login
- Role detection → routes to admin or user screen automatically
- Session stored with SharedPreferences (token-based)
- Auto-login on app relaunch
- Logout from any screen

### REST API Integration (5+ Endpoints used)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/login` | Login |
| POST | `/api/register` | Register new user |
| POST | `/api/logout` | Logout |
| GET | `/api/user/bills` | Get user's bills |
| POST | `/api/user/bills/{id}/pay` | Pay a bill |
| GET | `/api/user/profile` | Get user profile |
| PUT | `/api/user/profile` | Update profile |
| GET | `/api/admin/dashboard` | Admin stats |
| GET | `/api/admin/bills` | All bills |
| POST | `/api/admin/bills` | Add new bill |
| GET | `/api/admin/users` | All users |

### Working Features (3+)
1. **View Bills** — User can see all their electricity bills with status (paid/unpaid/overdue), kWh consumed, amount due, billing date
2. **Pay Bill** — User can pay a bill with choice of: Cash, GCash, Maya, or Bank Transfer
3. **Search Functionality** — Both users and admin can search bills by name, date, meter number, status; admin can search customers
4. **Edit Profile** — User can update their personal info and address
5. **Admin: Add Bill** — Admin can add a bill for any registered customer
6. **Admin: View All Users** — Admin can browse and view detailed customer info

---

## 🚀 Setup Instructions

### Step 1 — Prerequisites
Make sure you have Flutter installed:
```bash
flutter --version   # should be 3.x or higher
```

### Step 2 — Install Dependencies
```bash
cd ebill_flutter
flutter pub get
```

### Step 3 — Set the API Base URL
Open `lib/services/api_service.dart` and update line 6:
```dart
// Change this to your classmate's deployed Laravel URL
static const String baseUrl = 'http://YOUR_LARAVEL_API_URL/api';

// Example (local):
static const String baseUrl = 'http://192.168.1.10/e_bill/api';

// Example (online):
static const String baseUrl = 'https://yourdomain.com/api';
```

> ⚠️ **Important:** If testing on a real Android device, you **cannot** use `localhost`. Use your computer's local IP address (e.g. `192.168.1.x`).

### Step 4 — Android Network Permission
In `android/app/src/main/AndroidManifest.xml`, add before `<application`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
For HTTP (non-HTTPS) in debug, also add inside `<application`:
```xml
android:usesCleartextTraffic="true"
```

### Step 5 — Run the App
```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device_id>

# Or just:
flutter run
```

---

## 🔌 What the Laravel Backend Needs to Expose

Tell your classmate to create these API routes in `routes/api.php`:

```php
// Public
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// Protected (requires auth:sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // User routes
    Route::get('/user/bills', [BillController::class, 'myBills']);
    Route::get('/user/bills/{id}', [BillController::class, 'showBill']);
    Route::post('/user/bills/{id}/pay', [BillController::class, 'pay']);
    Route::get('/user/profile', [ProfileController::class, 'show']);
    Route::put('/user/profile', [ProfileController::class, 'update']);

    // Admin routes
    Route::middleware('role:admin')->group(function () {
        Route::get('/admin/dashboard', [AdminController::class, 'dashboard']);
        Route::get('/admin/bills', [AdminController::class, 'allBills']);
        Route::post('/admin/bills', [AdminController::class, 'addBill']);
        Route::get('/admin/users', [AdminController::class, 'allUsers']);
        Route::get('/admin/users/{id}', [AdminController::class, 'showUser']);
    });
});
```

### Expected JSON Response Format

**Login:**
```json
{
  "success": true,
  "role": "user",
  "token": "1|abc123...",
  "id": 1,
  "name": "Redeemer Aparece",
  "username": "redeemer"
}
```

**Get Bills:**
```json
{
  "success": true,
  "bills": [
    {
      "id": 1,
      "billing_date": "2026-03-23",
      "due_date": "2026-04-22",
      "kwh_consumed": "11.00",
      "amount_due": "121.00",
      "status": "paid"
    }
  ]
}
```

**Pay Bill:**
```json
{ "success": true, "payment_uuid": "abc-123" }
```

**Admin Dashboard:**
```json
{
  "success": true,
  "total_users": 5,
  "total_bills": 12,
  "total_paid": 8,
  "total_unpaid": 4,
  "total_revenue": 4400.00,
  "rate": 11
}
```

---

## 📱 Screens Overview

| Screen | Role | Description |
|--------|------|-------------|
| Splash | Both | Auto-detects login state |
| Login | Both | Sign in |
| Register | User | New account |
| User Dashboard | User | Bills overview + balance |
| My Bills | User | Full bill list + search + filter |
| Pay Bill | User | Payment with method selection |
| Profile | User | View + edit personal info |
| Admin Dashboard | Admin | Stats + revenue |
| Admin Bills | Admin | All bills + search + add |
| Add Bill | Admin | Create bill for a customer |
| Admin Users | Admin | All customers + search + detail |

---

## 🎨 Design Notes
- Primary color: `#1565C0` (blue)
- Uses Material Design 3
- Responsive for all Android screen sizes
- Pull-to-refresh on all list screens
- Loading states and error handling throughout
