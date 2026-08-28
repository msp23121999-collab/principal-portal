import { pool } from '../config/database';

export class AuthRepository {
  static async findUserByEmail(email: string) {
    const result = await pool.query(
      `SELECT u.*, d.name as department_name, d.code as department_code 
       FROM public.users u
       LEFT JOIN public.departments d ON u.department_id = d.id
       WHERE LOWER(u.email) = LOWER($1) AND u.status = 'Active'`,
      [email]
    );
    return result.rows[0];
  }

  static async findUserById(id: string) {
    const result = await pool.query(
      `SELECT u.*, d.name as department_name 
       FROM public.users u
       LEFT JOIN public.departments d ON u.department_id = d.id
       WHERE u.id = $1`,
      [id]
    );
    return result.rows[0];
  }
}
