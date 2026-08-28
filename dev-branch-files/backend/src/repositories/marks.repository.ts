import { pool } from '../config/database';

export class MarksRepository {
  static async findByStudent(studentId: string) {
    const result = await pool.query(
      `SELECT sm.*, sub.name as subject_name, sub.subject_code, sub.credits 
       FROM public.student_marks sm
       JOIN public.subjects sub ON sm.subject_id = sub.id
       WHERE sm.student_id = $1
       ORDER BY sub.subject_code`,
      [studentId]
    );
    return result.rows;
  }
}
