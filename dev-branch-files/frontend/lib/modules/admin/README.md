# Admin Module - Flutter ERP

Complete admin module for the Unified College Academic Management System (CAMS) ERP application.

## 📋 Module Structure

```
admin/
├── app/                    # App-level configuration
├── erp_repository.dart    # Data repository layer
├── erp_services.dart      # Business logic services
├── main.dart              # Admin app entry point
├── models/                # Data models
├── pages/                 # Admin pages/screens
├── services/              # Feature-specific services
├── theme.dart             # Theme configuration
├── utils/                 # Utility functions
├── widgets/               # Reusable widgets
└── pubspec.yaml          # Dependencies
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.12+
- Dart 3.12+
- A running Firebase project
- Supabase project credentials

### Installation

1. **Install Dependencies**
   ```bash
   cd frontend/lib/modules/admin
   flutter pub get
   ```

2. **Install Root Dependencies**
   ```bash
   cd ../../..
   flutter pub get
   ```

3. **Configure Firebase** (if not already done in main app)
   - Copy Firebase configuration from `lib/core/firebase_options.dart`
   - Ensure `google-services.json` is in `android/app/`
   - Ensure `GoogleService-Info.plist` is in `ios/Runner/`

4. **Configure Environment Variables**
   - Create `.env` file in project root with:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_key
     FIREBASE_PROJECT_ID=your_firebase_project
     ```

## 📦 Key Dependencies

### State Management
- **flutter_riverpod** (v2.5.1) - Reactive state management

### Routing
- **go_router** (v17.3.0) - Declarative routing

### Data Persistence & APIs
- **supabase_flutter** (v2.6.0) - Supabase client
- **cloud_firestore** (v5.6.9) - Firebase Firestore
- **http** (v1.2.0) - HTTP client
- **postgres** (v3.1.2) - PostgreSQL driver

### UI Components
- **google_fonts** (v8.2.0) - Font library
- **fl_chart** (v1.2.0) - Charts and graphs
- **loading_animation_widget** (v1.3.0) - Loading animations

### Utilities
- **flutter_dotenv** (v5.2.1) - Environment variables
- **intl** (v0.20.2) - Internationalization
- **file_picker** (v5.3.0) - File selection
- **month_year_picker** (v0.5.0+1) - Date picking

## 🔧 Running the Admin Module

### As Part of Main App
```bash
cd frontend
flutter run
```

### Local Testing (Standalone)
```bash
cd frontend/lib/modules/admin
flutter pub get
# Copy dependencies from parent pubspec.lock if needed
```

## 📝 Common Commands

### Get Dependencies
```bash
flutter pub get
```

### Run Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format .
```

### Run Tests
```bash
flutter test
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## 🔐 Security Notes

⚠️ **Important**: This module requires:

1. **Supabase Configuration**
   - Anon key and URL from `.env`
   - Row Level Security (RLS) policies enabled
   - User authentication via Firebase/Cognito

2. **Firebase Setup**
   - Firebase project initialized
   - Cloud Firestore enabled
   - Authentication configured

3. **Database Access**
   - Admin role required for full access
   - Specific tables accessible based on permissions:
     - `users` (read/write own profile)
     - `departments` (read)
     - `faculties` (read/write)
     - `students` (read/write)
     - `academic_years` (read/write)
     - `subjects` (read/write)
     - `class_sections` (read/write)
     - And other admin-level tables

## 🐛 Troubleshooting

### Dependency Conflicts
If you get dependency resolution errors:
```bash
flutter pub upgrade
flutter pub get --no-offline
```

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Firebase Initialization Issues
Ensure `lib/core/firebase_options.dart` exists and is properly configured:
```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminModule());
}
```

### Supabase Connection Issues
Check `.env` file has correct credentials:
```bash
# Should contain:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## 📚 Documentation Files

Related documentation in the project:
- [Main ERP README](../../../README.md) - Project overview
- [Migration Guide](../../../docs/README_MIGRATION_GUIDE.md) - Supabase to AWS migration
- [API Architecture](../../../docs/BACKEND_API_ARCHITECTURE.md) - Backend API design
- [Database Schema](../../../database/canonical_schema.sql) - Database structure

## 🔄 Module Dependencies

This admin module depends on:
- **Shared Widgets**: `lib/shared/widgets/`
- **Shared Services**: `lib/shared/services/`
- **Core Configuration**: `lib/core/firebase_options.dart`
- **Router**: `lib/app/router.dart`
- **Main App**: Must be run as part of the main Flutter app

## 📊 Admin Module Features

### User Management
- View/edit admin users
- Assign roles and permissions
- Manage access control

### Department Management
- Create/edit departments
- Manage department heads
- Track department budgets

### Faculty Management
- Faculty profiles
- Work allocation
- Performance tracking

### Student Management
- Student registration
- Academic progress tracking
- Document management

### Academic Calendar
- Year configuration
- Semester setup
- Holiday management

### Reports & Analytics
- User activity reports
- System health dashboard
- Custom reports

## 🚢 Deployment

### Development
```bash
flutter run -d chrome  # Web development
flutter run -d emulator  # Android emulator
```

### Production
```bash
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review related documentation files
3. Check Flutter and package documentation
4. Contact the development team

## 📄 License

Part of the Unified College Academic Management System (CAMS) ERP
