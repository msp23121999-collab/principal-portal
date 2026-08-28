import { pool } from '../config/database';

export class AttendanceRepository {
  static async findRecordsByStudent(studentId: string) {
    const result = await pool.query(
      `SELECT ar.*, s.session_date, s.session_name, sub.name as subject_name 
       FROM public.attendance_records ar
       JOIN public.attendance_sessions s ON ar.session_id = s.id
       LEFT JOIN public.subjects sub ON s.subject_id = sub.id
       WHERE ar.student_id = $1
       ORDER BY s.session_date DESC`,
      [studentId]
    );
    return result.rows;
  }

  static async findSummaryByStudent(studentId: string) {
    const result = await pool.query(
      `SELECT * FROM public.student_attendance_summary WHERE student_id = $1`,
      [studentId]
    );
    return result.rows[0];
  }
}
