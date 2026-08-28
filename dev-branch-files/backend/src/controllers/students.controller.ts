import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { StudentsRepository } from '../repositories/students.repository';
import { sendSuccess, sendError } from '../utils/response';

export class StudentsController {
  static async getAllStudents(req: AuthRequest, res: Response) {
    try {
      const limit = Number(req.query.limit || 100);
      const offset = Number(req.query.offset || 0);
      const students = await StudentsRepository.findAll(limit, offset);
      return sendSuccess(res, students, 'Students retrieved successfully', 200, students.length);
    } catch (err: any) {
      return sendError(res, err.message, 500);
    }
  }

  static async getStudentById(req: AuthRequest, res: Response) {
    try {
      const idParam = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const student = await StudentsRepository.findById(idParam);
      if (!student) return sendError(res, 'Student not found', 404);
      return sendSuccess(res, student, 'Student details retrieved');
    } catch (err: any) {
      return sendError(res, err.message, 500);
    }
  }
}
