import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/leave_request.dart';

/// Reads staff leave applications from `faculty.leave_applications`.
///
/// Approving or rejecting updates only this portal's copy — the source table
/// belongs to the Faculty Portal and is never written to from here.
class LeaveRepository extends Repository {
  const LeaveRepository();

  Future<Sourced<List<LeaveRequest>>> fetchAll() {
    return load<List<LeaveRequest>>(
      debugLabel: 'faculty.leave_applications',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        // The roster is fetched alongside so applications can show who
        // submitted them; the applications table stores only an employee id.
        final results = await Future.wait([
          ApiClient.schema(
            DbSchema.faculty,
          ).from('leave_applications').select(),
          ApiClient.schema(
            DbSchema.faculty,
          ).from('faculties').select('employee_id, full_name'),
        ]);

        final names = <String, String>{
          for (final raw in results[1])
            if (Map<String, dynamic>.from(raw).str('employee_id') != null)
              Map<String, dynamic>.from(raw).str('employee_id')!:
                  Map<String, dynamic>.from(raw).strOr('full_name', ''),
        }..removeWhere((_, name) => name.isEmpty);

        final requests = [
          for (final row in results[0])
            _toRequest(Map<String, dynamic>.from(row), names),
        ];
        requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        return requests;
      },
    );
  }

  /// Maps one `faculty.leave_applications` row.
  ///
  /// The table identifies the applicant only by `faculty_employee_id` — it
  /// stores no name — so [names] supplies one where the roster can resolve
  /// it. Where it cannot, the employee id is shown rather than a blank or a
  /// placeholder that would hide who the request belongs to.
  LeaveRequest _toRequest(Map<String, dynamic> row, Map<String, String> names) {
    final now = DateTime.now();
    final fromDate = row.dateOr('start_date', row.dateOr('from_date', now));
    final employeeId = row.firstStr(['faculty_employee_id']) ?? '';

    return LeaveRequest(
      id: row.firstStr(['id', 'display_id']) ?? '',
      requesterName:
          names[employeeId] ??
          (employeeId.isEmpty ? 'Unknown applicant' : employeeId),
      requesterRole: 'Faculty',
      leaveType: row.firstStr(['leave_type', 'type', 'category']) ?? 'Leave',
      fromDate: fromDate,
      toDate: row.dateOr('end_date', row.dateOr('to_date', fromDate)),
      reason: row.firstStr(['reason', 'hod_remarks', 'remarks']) ?? '',
      status: _statusFrom(row.firstStr(['status', 'approval_status'])),
      submittedAt: row.dateOr(
        'applied_date',
        row.dateOr('created_at', fromDate),
      ),
    );
  }

  LeaveStatus _statusFrom(String? raw) {
    final text = (raw ?? '').toLowerCase();
    if (text.contains('approve')) return LeaveStatus.approved;
    if (text.contains('reject') || text.contains('decline')) {
      return LeaveStatus.rejected;
    }
    return LeaveStatus.pending;
  }
}
