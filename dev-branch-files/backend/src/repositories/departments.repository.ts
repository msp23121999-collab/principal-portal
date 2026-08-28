import { pool } from '../config/database';

export class DepartmentsRepository {
  static async findAll() {
    const result = await pool.query(
      `SELECT d.*, 
        (SELECT COUNT(*) FROM public.students s WHERE s.department_id = d.id) as student_count,
        (SELECT COUNT(*) FROM public.faculties f WHERE f.department_id = d.id) as faculty_count
       FROM public.departments d
       ORDER BY d.code`
    );
    return result.rows;
  }

  static async findById(id: string) {
    const result = await pool.query(
      `SELECT * FROM public.departments WHERE id = $1 OR code = $1`,
      [id]
    );
    return result.rows[0];
  }
}
