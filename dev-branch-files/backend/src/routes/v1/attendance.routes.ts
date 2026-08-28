import { Router, Response } from 'express';
import { authenticateJwt, AuthRequest } from '../../middleware/auth.middleware';
import { pool } from '../../config/database';
import { sendSuccess, sendError } from '../../utils/response';

export const attendanceRouter = Router();
attendanceRouter.use(authenticateJwt);

attendanceRouter.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM public.attendance_records ORDER BY created_at DESC LIMIT 100');
    return sendSuccess(res, result.rows, 'Attendance records retrieved');
  } catch (err: any) {
    return sendError(res, err.message, 500);
  }
});
