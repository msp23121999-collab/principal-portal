# KSRCE ERP - Node.js Backend API
## Architecture & Implementation Guide

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js          # RDS PostgreSQL connection pool
│   │   ├── secrets.js           # AWS Secrets Manager integration
│   │   ├── s3.js                # S3 client configuration
│   │   ├── cognito.js           # Cognito JWT verification
│   │   └── environment.js       # Environment variables validation
│   │
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   ├── authorization.js     # Role-based access control (RBAC)
│   │   ├── errorHandler.js      # Global error handling
│   │   ├── logger.js            # Request/response logging
│   │   ├── requestValidator.js  # Input validation
│   │   └── cors.js              # CORS configuration
│   │
│   ├── routes/
│   │   ├── student.js           # Student endpoints
│   │   ├── faculty.js           # Faculty endpoints
│   │   ├── attendance.js        # Attendance management
│   │   ├── marks.js             # Marks & assessment
│   │   ├── timetable.js         # Timetable
│   │   ├── admin.js             # Admin functions
│   │   ├── hod.js               # HOD functions
│   │   ├── auth.js              # Authentication (login, logout, token refresh)
│   │   ├── files.js             # File upload/download
│   │   ├── notifications.js     # Notifications
│   │   └── health.js            # Health check
│   │
│   ├── controllers/
│   │   ├── studentController.js
│   │   ├── facultyController.js
│   │   ├── attendanceController.js
│   │   ├── marksController.js
│   │   ├── fileController.js
│   │   └── [other controllers]
│   │
│   ├── services/
│   │   ├── studentService.js
│   │   ├── facultyService.js
│   │   ├── attendanceService.js
│   │   ├── marksService.js
│   │   ├── fileService.js       # S3 integration
│   │   ├── emailService.js      # SES integration (optional)
│   │   └── [other services]
│   │
│   ├── repositories/
│   │   ├── studentRepository.js
│   │   ├── facultyRepository.js
│   │   ├── attendanceRepository.js
│   │   └── [other repositories]  # Data access layer
│   │
│   ├── utils/
│   │   ├── errors.js            # Custom error classes
│   │   ├── validators.js        # Input validation schemas
│   │   ├── helpers.js           # Utility functions
│   │   └── constants.js         # Constants & enums
│   │
│   ├── migrations/
│   │   ├── 001_create_tables.sql
│   │   ├── 002_add_indexes.sql
│   │   └── [schema migrations]
│   │
│   └── app.js                   # Express app setup
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── .env.example                 # Environment template
├── .env.production              # Production env (in Secrets Manager)
├── package.json
├── package-lock.json
├── docker-compose.yml           # Local development
├── Dockerfile                   # Container image
└── README.md

```

## Core Files

### 1. app.js - Express Setup

```javascript
// src/app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');

const authMiddleware = require('./middleware/auth');
const authorizationMiddleware = require('./middleware/authorization');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./middleware/logger');

// Routes
const studentRoutes = require('./routes/student');
const facultyRoutes = require('./routes/faculty');
const attendanceRoutes = require('./routes/attendance');
const marksRoutes = require('./routes/marks');
const adminRoutes = require('./routes/admin');
const hodRoutes = require('./routes/hod');
const authRoutes = require('./routes/auth');
const fileRoutes = require('./routes/files');
const healthRoutes = require('./routes/health');

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Logging & Compression
app.use(morgan('combined', {
  stream: {
    write: (message) => logger.info(message.trim())
  }
}));
app.use(compression());

// Body Parser
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Request Logger
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Health Check (No Auth Required)
app.use('/health', healthRoutes);

// Public Routes (No Auth)
app.use('/api/v1/auth', authRoutes);

// Protected Routes (Auth Required)
app.use('/api/v1/auth', authMiddleware);

// Student Routes
app.use('/api/v1/students', authMiddleware, authorizationMiddleware(['STUDENT']), studentRoutes);

// Faculty Routes
app.use('/api/v1/faculty', authMiddleware, authorizationMiddleware(['FACULTY', 'HOD']), facultyRoutes);

// Attendance Routes
app.use('/api/v1/attendance', authMiddleware, authorizationMiddleware(['FACULTY', 'HOD', 'ADMIN']), attendanceRoutes);

// Marks Routes
app.use('/api/v1/marks', authMiddleware, authorizationMiddleware(['FACULTY', 'HOD', 'ADMIN']), marksRoutes);

// Admin Routes
app.use('/api/v1/admin', authMiddleware, authorizationMiddleware(['ADMIN', 'SUPER_ADMIN']), adminRoutes);

// HOD Routes
app.use('/api/v1/hod', authMiddleware, authorizationMiddleware(['HOD', 'SUPER_ADMIN']), hodRoutes);

// File Routes (with Auth)
app.use('/api/v1/files', authMiddleware, fileRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    path: req.path,
    method: req.method
  });
});

// Global Error Handler (MUST be last)
app.use(errorHandler);

module.exports = app;
```

### 2. middleware/auth.js - JWT Verification

```javascript
// src/middleware/auth.js
const { verify } = require('jsonwebtoken');
const { CognitoJwtVerifier } = require('aws-jwt-verify');
const logger = require('./logger');
const UnauthorizedError = require('../utils/errors');

const verifier = CognitoJwtVerifier.create({
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  tokenUse: 'access',
  clientId: process.env.COGNITO_CLIENT_ID,
});

async function authMiddleware(req, res, next) {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      throw new UnauthorizedError('No token provided');
    }

    // Verify Cognito token
    const payload = await verifier.verify(token);

    // Attach user info to request
    req.user = {
      id: payload.sub,
      email: payload.email,
      role: payload['custom:role'],
      department: payload['custom:department'],
      studentId: payload['custom:student_id'],
      employeeId: payload['custom:employee_id'],
      username: payload.username,
      tokenExpiry: new Date(payload.exp * 1000)
    };

    logger.info('Token verified', { userId: req.user.id, role: req.user.role });
    next();
  } catch (error) {
    logger.error('Authentication failed', { error: error.message });
    res.status(401).json({
      success: false,
      error: 'Authentication failed',
      message: error.message
    });
  }
}

module.exports = authMiddleware;
```

### 3. middleware/authorization.js - RBAC

```javascript
// src/middleware/authorization.js
const ForbiddenError = require('../utils/errors');
const logger = require('./logger');

function authorizationMiddleware(allowedRoles = []) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'User not authenticated'
      });
    }

    if (allowedRoles.length === 0) {
      // No role restriction
      return next();
    }

    if (!allowedRoles.includes(req.user.role)) {
      logger.warn('Authorization failed', {
        userId: req.user.id,
        userRole: req.user.role,
        allowedRoles,
        path: req.path
      });

      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions',
        message: `This resource requires one of: ${allowedRoles.join(', ')}`
      });
    }

    next();
  };
}

module.exports = authorizationMiddleware;
```

### 4. config/database.js - RDS Connection Pool

```javascript
// src/config/database.js
const { Pool } = require('pg');
const AWS = require('aws-sdk');
const logger = require('../middleware/logger');

const secretsManager = new AWS.SecretsManager({ region: process.env.AWS_REGION });

let pool = null;

async function initializePool() {
  if (pool) return pool;

  try {
    // Get RDS credentials from Secrets Manager
    const secretArn = process.env.RDS_SECRET_ARN;
    const secret = await secretsManager.getSecretValue({ SecretId: secretArn }).promise();
    const credentials = JSON.parse(secret.SecretString);

    pool = new Pool({
      host: credentials.host.split(':')[0],
      port: credentials.port || 5432,
      database: credentials.dbname,
      user: credentials.username,
      password: credentials.password,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
      application_name: 'ksrce-erp-backend',
      statement_timeout: 30000, // 30 seconds
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });

    pool.on('error', (err) => {
      logger.error('Unexpected pool error', { error: err });
    });

    pool.on('connect', () => {
      logger.info('New connection to RDS');
    });

    // Test connection
    const testConnection = await pool.query('SELECT NOW()');
    logger.info('RDS connection pool initialized', { timestamp: testConnection.rows[0].now });

    return pool;
  } catch (error) {
    logger.error('Failed to initialize database pool', { error: error.message });
    throw error;
  }
}

async function query(text, values = []) {
  const start = Date.now();
  try {
    const result = await pool.query(text, values);
    const duration = Date.now() - start;
    
    if (duration > 1000) {
      logger.warn('Slow query detected', { query: text, duration });
    }
    
    return result;
  } catch (error) {
    logger.error('Database query error', { 
      error: error.message,
      query: text,
      duration: Date.now() - start
    });
    throw error;
  }
}

async function queryOne(text, values = []) {
  const result = await query(text, values);
  return result.rows[0];
}

async function queryAll(text, values = []) {
  const result = await query(text, values);
  return result.rows;
}

async function transaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  initializePool,
  query,
  queryOne,
  queryAll,
  transaction,
  getPool: () => pool
};
```

### 5. services/studentService.js - Business Logic

```javascript
// src/services/studentService.js
const db = require('../config/database');
const logger = require('../middleware/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');

class StudentService {
  async getStudentProfile(userId) {
    const student = await db.queryOne(
      `SELECT s.*, d.name as department_name, d.code as department_code
       FROM students s
       LEFT JOIN departments d ON s.department_id = d.id
       WHERE s.user_id = $1 AND s.status = 'Continuing'`,
      [userId]
    );

    if (!student) {
      throw new NotFoundError('Student profile not found');
    }

    return this.formatStudentResponse(student);
  }

  async getStudentAttendance(studentId) {
    const attendance = await db.queryAll(
      `SELECT 
        COUNT(*) as total_sessions,
        COUNT(*) FILTER (WHERE status = 'PRESENT') as present,
        COUNT(*) FILTER (WHERE status = 'ABSENT') as absent,
        COUNT(*) FILTER (WHERE status = 'OD') as od,
        ROUND((COUNT(*) FILTER (WHERE status IN ('PRESENT', 'OD'))::numeric / COUNT(*) * 100), 2) as percentage
       FROM attendance_records
       WHERE student_id = $1`,
      [studentId]
    );

    return attendance[0];
  }

  async getStudentMarks(studentId) {
    const marks = await db.queryAll(
      `SELECT 
        sm.id, sm.subject_id, s.name as subject_name,
        sm.cia_score, sm.assignment_score, sm.end_semester_score,
        sm.total_score, sm.grade, sm.grade_points,
        f.full_name as faculty_name,
        sm.status, sm.submitted_at, sm.approved_at
       FROM student_marks sm
       JOIN subjects s ON sm.subject_id = s.id
       LEFT JOIN faculties f ON sm.faculty_id = f.id
       WHERE sm.student_id = $1
       ORDER BY s.name`,
      [studentId]
    );

    return marks;
  }

  async downloadCertificate(studentId, certificateType) {
    // Validate request
    const validTypes = ['Bonafide', 'Conduct', 'Transfer', 'CourseCompletion'];
    if (!validTypes.includes(certificateType)) {
      throw new ValidationError(`Invalid certificate type: ${certificateType}`);
    }

    // Check if certificate already generated
    const existing = await db.queryOne(
      `SELECT * FROM certificate_requests 
       WHERE student_id = $1 AND certificate_type = $2 AND status = 'Generated'`,
      [studentId, certificateType]
    );

    if (existing) {
      return { url: existing.download_url };
    }

    // Generate certificate (Lambda call or PDF generation)
    // ... certificate generation logic
    
    return { message: 'Certificate will be available shortly' };
  }

  formatStudentResponse(student) {
    return {
      id: student.id,
      studentId: student.student_id,
      rollNumber: student.roll_number,
      fullName: student.full_name,
      email: student.institute_email || student.personal_email,
      department: {
        id: student.department_id,
        code: student.department_code,
        name: student.department_name
      },
      academicInfo: {
        semester: student.current_semester,
        section: student.section,
        cgpa: parseFloat(student.cgpa),
        attendance: parseFloat(student.attendance_percentage)
      },
      status: student.status
    };
  }
}

module.exports = new StudentService();
```

### 6. routes/student.js - API Routes

```javascript
// src/routes/student.js
const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const { validateQuery } = require('../middleware/requestValidator');

// GET /api/v1/students/profile
router.get('/profile', async (req, res, next) => {
  try {
    const profile = await studentController.getProfile(req);
    res.json({ success: true, data: profile });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/students/attendance
router.get('/attendance', async (req, res, next) => {
  try {
    const attendance = await studentController.getAttendance(req);
    res.json({ success: true, data: attendance });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/students/marks
router.get('/marks', async (req, res, next) => {
  try {
    const marks = await studentController.getMarks(req);
    res.json({ success: true, data: marks });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/students/timetable
router.get('/timetable', async (req, res, next) => {
  try {
    const timetable = await studentController.getTimetable(req);
    res.json({ success: true, data: timetable });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/students/certificates
router.get('/certificates', async (req, res, next) => {
  try {
    const certificates = await studentController.getCertificates(req);
    res.json({ success: true, data: certificates });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

### 7. utils/errors.js - Custom Errors

```javascript
// src/utils/errors.js

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message) {
    super(message, 400);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403);
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404);
  }
}

class ConflictError extends AppError {
  constructor(message) {
    super(message, 409);
  }
}

class InternalServerError extends AppError {
  constructor(message = 'Internal server error') {
    super(message, 500);
  }
}

module.exports = {
  AppError,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  InternalServerError
};
```

## API Endpoints Overview

```
BASE_URL: https://api.ksrce.ac.in/api/v1

# AUTHENTICATION (No Auth Required)
POST   /auth/login              # Cognito login
POST   /auth/refresh-token      # Refresh JWT
POST   /auth/logout             # Logout
POST   /auth/forgot-password    # Password reset

# STUDENT ENDPOINTS (STUDENT Role)
GET    /students/profile        # Get student profile
GET    /students/attendance     # Get attendance summary
GET    /students/marks          # Get marks
GET    /students/timetable      # Get timetable
GET    /students/courses        # Get enrolled courses
GET    /students/certificates  # List certificates
POST   /students/certificates/{type}/request  # Request certificate
GET    /students/notifications  # Get notifications
POST   /students/grievances     # Submit grievance
GET    /students/achievements   # List achievements
GET    /students/fees           # Get fees status

# FACULTY ENDPOINTS (FACULTY Role)
GET    /faculty/profile         # Get faculty profile
GET    /faculty/allocations     # Get course allocations
POST   /faculty/attendance/start-session     # Start attendance session
POST   /faculty/attendance/mark              # Mark attendance
GET    /faculty/marks/view      # View marks
POST   /faculty/marks/submit    # Submit marks
POST   /faculty/assignments/create  # Create assignment
GET    /faculty/assignments/{id}/submissions # View submissions
POST   /faculty/assignments/{id}/grade       # Grade assignment
POST   /faculty/question-bank   # Add questions
GET    /faculty/timetable       # Get timetable
POST   /faculty/leave-application # Apply for leave

# HOD ENDPOINTS (HOD Role)
GET    /hod/department          # Department overview
GET    /hod/faculty-list        # Faculty in department
GET    /hod/attendance-report   # Department attendance
GET    /hod/marks-analytics     # Marks analytics
POST   /hod/leave-applications/{id}/approve  # Approve leave
GET    /hod/documents           # Manage documents
POST   /hod/documents/upload    # Upload document

# ADMIN ENDPOINTS (ADMIN Role)
POST   /admin/users/create      # Create user
GET    /admin/users/{id}        # Get user details
PUT    /admin/users/{id}        # Update user
DELETE /admin/users/{id}        # Delete user
POST   /admin/departments       # Manage departments
POST   /admin/academic-year     # Set academic year
POST   /admin/system-settings   # Configure settings
GET    /admin/audit-logs        # View audit logs
GET    /admin/reports           # Generate reports

# FILE OPERATIONS (All Authenticated Users)
POST   /files/upload            # Upload file to S3
GET    /files/{id}/download     # Download file (presigned URL)
DELETE /files/{id}              # Delete file
GET    /files/my                # List user's files

# HEALTH CHECKS (No Auth Required)
GET    /health                  # Health check
GET    /health/db               # Database health
GET    /health/s3               # S3 connectivity
```

## Deployment

### Docker

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY src ./src
COPY .env.production .env

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000

CMD ["node", "src/index.js"]
```

### Lambda Deployment

```bash
# Package for Lambda
zip -r lambda.zip src/ node_modules/

# Deploy with AWS CLI
aws lambda update-function-code \
  --function-name ksrce-erp-p-api \
  --zip-file fileb://lambda.zip
```

## Environment Variables

```env
# Node Environment
NODE_ENV=production

# AWS
AWS_REGION=ap-south-1
AWS_ACCOUNT_ID=123456789012

# RDS
RDS_SECRET_ARN=arn:aws:secretsmanager:ap-south-1:123456789012:secret:ksrce-erp-p/rds/password

# Cognito
COGNITO_USER_POOL_ID=ap-south-1_xxxxxxxxx
COGNITO_CLIENT_ID=abc123def456

# S3
S3_STUDENT_BUCKET=ksrce-erp-student-files-123456789012
S3_FACULTY_BUCKET=ksrce-erp-faculty-files-123456789012
S3_DEPARTMENT_BUCKET=ksrce-erp-department-files-123456789012

# API
API_PORT=3000
LOG_LEVEL=info
ALLOWED_ORIGINS=https://flutter.ksrce.ac.in,https://web.ksrce.ac.in

# Security
JWT_SECRET=your-secret-key-here
CORS_CREDENTIALS=true
```

---

**Status**: Architecture document ready for Phase 6 implementation

