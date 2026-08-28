import { Router, Response } from 'express';
import { authenticateJwt, AuthRequest } from '../../middleware/auth.middleware';
import { pool } from '../../config/database';
import { sendSuccess, sendError } from '../../utils/response';

export const marksRouter = Router();
marksRouter.use(authenticateJwt);

marksRouter.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM public.student_marks ORDER BY created_at DESC LIMIT 100');
    return sendSuccess(res, result.rows, 'Marks retrieved');
  } catch (err: any) {
    return sendError(res, err.message, 500);
  }
});
