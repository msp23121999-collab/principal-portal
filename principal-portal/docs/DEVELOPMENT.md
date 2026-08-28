# Principal Portal Development Guide

## 1. Environment Setup

### Prerequisites
- Flutter SDK (v3.19+ / Dart 3.11+)
- Node.js (v18+)
- Google Chrome

---

## 2. Configuration Files

### `.env` (Backend Root)
Configures database host, credentials, JWT secrets, and server ports. Ensure `.env` is present in the workspace root directory:
```env
PORT=3000
NODE_ENV=development
REQUIRE_AUTH=false
DATABASE_HOST=13.204.53.209
DATABASE_PORT=5432
DATABASE_NAME=ksrerp
DATABASE_USER=ksrce-user
DATABASE_PASSWORD=<your-db-password>
```

---

## 3. Running locally

### 1. Start Backend API
```bash
cd ../finalcode-worktree/backend
node server.js
```

### 2. Start Flutter Web Frontend
```bash
flutter run -d chrome --dart-define=SUPABASE_URL=http://localhost:3000
```
Or execute `run-live.bat`.
