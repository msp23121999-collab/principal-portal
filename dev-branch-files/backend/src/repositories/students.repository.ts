import { pool } from '../config/database';

export class StudentsRepository {
  static async findAll(limit = 100, offset = 0) {
    const result = await pool.query(
      `SELECT s.*, d.name as department_name, d.code as department_code 
       FROM public.students s
       LEFT JOIN public.departments d ON s.department_id = d.id
       ORDER BY s.roll_number
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    return result.rows;
  }

  static async findById(id: string) {
    const result = await pool.query(
      `SELECT s.*, d.name as department_name 
       FROM public.students s
       LEFT JOIN public.departments d ON s.department_id = d.id
       WHERE s.id = $1 OR s.student_id = $1 OR s.roll_number = $1`,
      [id]
    );
    return result.rows[0];
  }
}
