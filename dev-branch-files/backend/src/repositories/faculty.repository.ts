import { pool } from '../config/database';

export class FacultyRepository {
  static async findAll(limit = 100, offset = 0) {
    const result = await pool.query(
      `SELECT f.*, d.name as department_name, d.code as department_code 
       FROM public.faculties f
       LEFT JOIN public.departments d ON f.department_id = d.id
       ORDER BY f.full_name
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    return result.rows;
  }

  static async findById(id: string) {
    const result = await pool.query(
      `SELECT f.*, d.name as department_name 
       FROM public.faculties f
       LEFT JOIN public.departments d ON f.department_id = d.id
       WHERE f.id = $1 OR f.employee_id = $1`,
      [id]
    );
    return result.rows[0];
  }
}
