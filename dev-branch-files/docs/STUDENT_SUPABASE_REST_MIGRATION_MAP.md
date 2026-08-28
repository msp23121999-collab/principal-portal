# Student Supabase to REST Migration Map

This map is based on the audited active service at `frontend/lib/modules/student/services/supabase_service.dart`. PostgreSQL object names are provisional until live catalog inspection confirms them. No student repository or query should be implemented from guessed columns.

| Existing service operation | New REST endpoint | Repository boundary | PostgreSQL source to verify |
| --- | --- | --- | --- |
| `getStudentProfile` | `GET /api/student/profile` | `StudentRepository.getStudentProfile` | Student identity/profile table in `student` or canonical live schema |
| `getStudentFamily` | `GET /api/student/family` | `StudentRepository.getFamily` | Family table and student foreign key |
| `getStudentEducation` | `GET /api/student/education` | `StudentRepository.getEducation` | Education table and student foreign key |
| `getStudentDocuments` | `GET /api/student/documents` | `StudentRepository.getDocuments` | Canonical document table plus storage metadata |
| `uploadStudentDocument` | `POST /api/student/documents` | `StudentRepository.createDocument` | Document metadata table; S3/storage integration to inspect |
| `getStudentFinancials`, `getFees`, `getFeesFiltered` | `GET /api/student/fees` | `StudentRepository.getFees` | Fees and financial tables; existing payment status semantics |
| `updateStudentProfile` | `PATCH /api/student/profile` | `StudentRepository.updateProfile` | Mutable profile columns and audit trigger/table |
| `getNotifications` | `GET /api/student/notifications` | `NotificationRepository.getForStudent` | Student notification table and notification triggers |
| `markNotificationRead`, `markAllNotificationsRead` | `PATCH /api/student/notifications/:id/read`, `PATCH /api/student/notifications/read-all` | `NotificationRepository.markRead` | Notification key and read-state columns |
| `getStudentMarks` | `GET /api/student/marks` | `MarksRepository.getStudentMarks` | Marks tables/views and existing calculation functions |
| `getStudentAttendance` | `GET /api/student/attendance` | `AttendanceRepository.getStudentAttendance` | Attendance tables/views and `student.*attendance*` functions |
| `getAssignmentMarks` | `GET /api/student/assignment-marks` | `MarksRepository.getAssignmentMarks` | Assignment-mark table and faculty notification/calculation triggers |
| `getAssignments` | `GET /api/student/assignments` | `AssignmentRepository.getAssignments` | Assignment table and student visibility relationship |
| `submitAssignment` | `POST /api/student/assignments/:id/submission` | `AssignmentRepository.submit` | Assignment submission table/columns and constraints |
| `uploadAssignmentFile` | `POST /api/student/assignments/:id/file` | `AssignmentRepository.createUpload` | Storage metadata; prefer backend-managed object storage |
| `getGrievances` | `GET /api/student/grievances` | `GrievanceRepository.getForStudent` | Grievance table and recipient function/trigger |
| `addGrievance`, `replyToGrievance` | `POST /api/student/grievances`, `PATCH /api/student/grievances/:id` | `GrievanceRepository.create`, `reply` | Grievance columns, ownership, `student.process_grievance_recipient()` |
| `getClassTimetables`, `getTimetables` | `GET /api/student/timetable` | `StudentRepository.getTimetable` | Timetable schema/table and section relationship |
| `getAcademicCalendarEvents` | `GET /api/student/calendar` | `StudentRepository.getCalendar` | Calendar event/view; choose one canonical live source |
| `getExamSchedules` | `GET /api/student/exams` | `StudentRepository.getExamSchedules` | Exam schedule table/view |
| `getSyllabus`, `getCourseMaterials`, `getLessonPlans` | `GET /api/student/learning-materials` | `StudentRepository.getLearningMaterials` | Faculty learning tables and storage metadata |
| `getStudentFamily`, documents, financials, certificates, achievements | Included in profile/dashboard aggregation as appropriate | `StudentRepository.getDashboard` | Existing views/functions preferred over duplicated aggregation |
| `getCertificates`, `addCertificateRequest` | `GET/POST /api/student/certificates` | `StudentRepository` or `CertificateRepository` | Certificate request table and status rules |
| `getAchievements`, `addAchievement` | `GET/POST /api/student/achievements` | `StudentRepository` or `AchievementRepository` | Achievement table and ownership |
| `getExtraCourses`, `getExtraCourseEnrollments`, `enrollExtraCourse` | `GET /api/student/extra-courses`, `POST /api/student/extra-courses/:id/enroll` | `StudentRepository` | Course and enrollment tables/unique constraints |
| `getPlacements`, `getPlacementApplications`, `applyPlacement` | `GET /api/student/placements`, `GET/POST /api/student/placement-applications` | `StudentRepository` | Placement tables/eligibility rules |
| `getNotices`, bookmark operations | `GET /api/student/notices`, bookmark POST/DELETE | `NotificationRepository` | Notice and bookmark tables/constraints |
| `getFaculties`, `getCourseAllocations` | `GET /api/student/faculty`, `GET /api/student/course-allocations` | `StudentRepository` | Faculty/course allocation tables and visibility rules |
| `getTransportBuses`, `getStudentTransportPass` | `GET /api/student/transport`, `GET /api/student/transport/pass` | `StudentRepository` | Transport tables and student ownership |
| `getRegulations`, `getAcademicYears` | `GET /api/academic/regulations`, `GET /api/academic-years` | `AcademicRepository` | Public academic catalog tables |
| `submitExitSurveyLog`, `submitCourseFeedbackLog`, `submitStudentFeedbackResult` | `POST /api/student/feedback` | `FeedbackRepository` | Feedback/audit tables; validate structured payloads |

## First Student API Slice

Implement and test in this order after live catalog output is available:

1. `GET /api/student/profile`
2. `GET /api/student/dashboard`
3. `GET /api/student/attendance`
4. `GET /api/student/marks`
5. `GET /api/student/assignments`
6. `GET /api/student/notifications`
7. `GET /api/student/grievances`

The authenticated user ID must come from the backend token, not a Flutter query parameter. Every repository query must use parameter placeholders and enforce ownership server-side.