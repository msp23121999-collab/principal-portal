import { pool } from '../config/database';

export class LeaveRepository {
  static async findPendingForHod() {
    const result = await pool.query(
      `SELECT * FROM public.hod_leave_requests WHERE status = 'PENDING HOD' ORDER BY created_at DESC`
    );
    return result.rows;
  }

  static async updateStatus(id: string, status: string, remarks?: string) {
    const result = await pool.query(
      `UPDATE public.hod_leave_requests 
       SET status = $1, hod_remarks = $2, updated_at = NOW() 
       WHERE id = $3 RETURNING *`,
      [status, remarks || null, id]
    );
    return result.rows[0];
  }
}
