import '../models/leave_request.dart';

/// Seed leave requests spanning pending, approved, and rejected states.
class LeaveMockData {
  LeaveMockData._();

  static List<LeaveRequest> requests() => [
    LeaveRequest(
      id: 'lr01',
      requesterName: 'Dr. Karthik Subramani',
      requesterRole: 'Associate Professor, ECE',
      leaveType: 'Casual Leave',
      fromDate: DateTime(2026, 8, 3),
      toDate: DateTime(2026, 8, 5),
      reason: 'Family function out of town.',
      status: LeaveStatus.pending,
      submittedAt: DateTime(2026, 7, 29),
    ),
    LeaveRequest(
      id: 'lr02',
      requesterName: 'Ms. Divya Bharathi',
      requesterRole: 'Assistant Professor, IoT',
      leaveType: 'On-Duty Leave',
      fromDate: DateTime(2026, 8, 6),
      toDate: DateTime(2026, 8, 6),
      reason: 'Attending FDP workshop at IIT Madras.',
      status: LeaveStatus.pending,
      submittedAt: DateTime(2026, 7, 28),
    ),
    LeaveRequest(
      id: 'lr03',
      requesterName: 'Mr. Suresh Babu',
      requesterRole: 'Assistant Professor, EEE',
      leaveType: 'Medical Leave',
      fromDate: DateTime(2026, 8, 4),
      toDate: DateTime(2026, 8, 8),
      reason: 'Scheduled minor surgery and recovery.',
      status: LeaveStatus.pending,
      submittedAt: DateTime(2026, 7, 27),
    ),
    LeaveRequest(
      id: 'lr04',
      requesterName: 'Dr. Anitha Suresh',
      requesterRole: 'Associate Professor, CSE',
      leaveType: 'Casual Leave',
      fromDate: DateTime(2026, 7, 24),
      toDate: DateTime(2026, 7, 26),
      reason: 'Personal work.',
      status: LeaveStatus.approved,
      submittedAt: DateTime(2026, 7, 20),
    ),
    LeaveRequest(
      id: 'lr05',
      requesterName: 'Mr. Dinesh Kanna',
      requesterRole: 'Assistant Professor, Civil',
      leaveType: 'Casual Leave',
      fromDate: DateTime(2026, 7, 15),
      toDate: DateTime(2026, 7, 16),
      reason: 'Attending a family event.',
      status: LeaveStatus.rejected,
      submittedAt: DateTime(2026, 7, 10),
    ),
    LeaveRequest(
      id: 'lr06',
      requesterName: 'Dr. Gowtham Raj',
      requesterRole: 'Associate Professor, Mechanical',
      leaveType: 'On-Duty Leave',
      fromDate: DateTime(2026, 7, 12),
      toDate: DateTime(2026, 7, 12),
      reason: 'External examiner duty at a sister institution.',
      status: LeaveStatus.approved,
      submittedAt: DateTime(2026, 7, 8),
    ),
  ];
}
