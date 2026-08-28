import { Router, Response } from 'express';
import { authenticateJwt, AuthRequest } from '../../middleware/auth.middleware';
import { pool } from '../../config/database';
import { sendSuccess, sendError } from '../../utils/response';

export const departmentsRouter = Router();
departmentsRouter.use(authenticateJwt);

departmentsRouter.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM public.departments ORDER BY created_at DESC');
    return sendSuccess(res, result.rows, 'Departments retrieved');
  } catch (err: any) {
    return sendError(res, err.message, 500);
  }
});
