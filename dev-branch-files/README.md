<<<<<<< HEAD
# ERP Unified System - HOD Portal Updates

## 📋 Overview of Today's Updates (Jul 31, 2026)

---

### 1. 👤 HOD "My Profile" Section
**File:** `lib/modules/hod/views/profile_view.dart`

- **Header Banner**:
  - Displays Profile Photo Avatar, Name, Employee ID, Designation (HOD), Department, Date of Joining, Email, and Mobile Number.
  - Added **Edit Profile** and **Change Password** buttons at the top right of the header card.
- **8 Collapsible Sections** (click header to expand/collapse):
  1. **Personal Details**: Name, Gender, Date of Birth, Blood Group, Nationality, Marital Status.
  2. **Contact Details**: Official Email, Personal Email, Mobile Number, Emergency Contact, Residential Address.
  3. **Professional Details**: Employee ID, Department, Designation, Date of Joining, Experience, Reporting Authority.
  4. **Academic Qualifications**: Ph.D, Master's (M.E), Bachelor's (B.E), University, Specialization.
  5. **Teaching Details**: Current Subjects, Classes Assigned, Academic Year, Semester, Weekly Workload.
  6. **Research & Publications**: Journal Publications, Conference Papers, Patents, Grants, Research IDs.
  7. **Documents**: Resume/CV, Degree Certificates, Faculty ID Card, Appointment Order.
  8. **Login & Security**: Username, Last Login Time, Account Status, Change Password Trigger.
- **Layout & Clean UI**:
  - Displays field details in **2 columns** on desktop/laptop and **1 column** on mobile.
  - Displays **"Not Available"** for any empty or missing field.

---

### 2. 📌 Sidebar Navigation
**File:** `lib/modules/hod/widgets/sidebar_navigation.dart`

- Added **"My Profile"** option in the sidebar menu under **Dashboard**.
- **Sidebar colors remain unchanged** (`#0F172A` theme strictly preserved).

---

### 3. 📅 Academic Calendar & Events
**Files:** `lib/modules/hod/views/academic_calendar_events_view.dart` & `events_view.dart`

- **Full-Width Event Badges**: Events expand to the full width of each date box in the monthly calendar.
- **Scroll Per Date**:
  - Date box height expanded to `140px`.
  - Dates with 2 or more events have a smooth vertical scrollbar so you can scroll inside the box to view all next events.
  - Fixed pixel overflow errors.
- **Actions Column Cleanup**: Removed redundant green tick checkmark icon from event table action rows.

---

## 🛠 Summary of Modified Files

| File Path | Description of Changes |
| :--- | :--- |
| `lib/modules/hod/views/profile_view.dart` | Updated My Profile UI, added 8 collapsible cards, header card, Edit/Password modals. |
| `lib/modules/hod/widgets/sidebar_navigation.dart` | Added "My Profile" menu entry while preserving original sidebar colors. |
| `lib/modules/hod/views/academic_calendar_events_view.dart` | Made event cards full-width, added scrollable date cells (height 140px), removed green tick icon. |
| `lib/modules/hod/views/events_view.dart` | Full-width data table formatting and green checkmark icon cleanup. |
=======
<<<<<<< HEAD
# CAMS-Engineering
=======
# ERP Unified

This repository contains a professional structure for the KSRCE ERP project:

- `frontend/` — Flutter application
- `backend/` — Node.js API and database scripts
- `database/` — schema and migration files
- `docs/` — documentation and audits
- `deployment/` — Firebase deployment config

## Key notes

- Do not commit generated files such as `.dart_tool/`, `build/`, `.idea/`, `.metadata/`, or `node_modules/`.
- Use `frontend/.env.example` and `backend/.env.example` for environment settings.
- Keep Firebase deployment files under `deployment/`.
>>>>>>> 0027798 (Organize repository into frontend/backend/docs/database and prepare dev branch)
>>>>>>> 18852e4704d7f9efd581deb3f0a83d47643f2b50
