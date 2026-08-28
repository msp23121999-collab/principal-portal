import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { TimetableService } from '../services/timetable.service';
import { sendSuccess, sendError } from '../utils/response';

export class TimetableController {
  static async getSectionTimetable(req: AuthRequest, res: Response) {
    try {
      const paramVal = req.params.sectionId || req.query.sectionId;
      const sectionId = Array.isArray(paramVal) ? String(paramVal[0]) : String(paramVal || '');
      const data = await TimetableService.getSectionTimetable(sectionId);
      return sendSuccess(res, data, 'Section timetable retrieved successfully');
    } catch (err: any) {
      return sendError(res, err.message, 400);
    }
  }

  static async getFacultyTimetable(req: AuthRequest, res: Response) {
    try {
      const paramVal = req.params.facultyId || req.query.facultyId;
      const facultyId = Array.isArray(paramVal) ? String(paramVal[0]) : String(paramVal || '');
      const data = await TimetableService.getFacultyTimetable(facultyId);
      return sendSuccess(res, data, 'Faculty timetable retrieved successfully');
    } catch (err: any) {
      return sendError(res, err.message, 400);
    }
  }

  static async createSlot(req: AuthRequest, res: Response) {
    try {
      const slot = await TimetableService.createTimetableSlot(req.body);
      return sendSuccess(res, slot, 'Timetable slot created successfully', 201);
    } catch (err: any) {
      return sendError(res, err.message, 400);
    }
  }

  static async deleteSlot(req: AuthRequest, res: Response) {
    try {
      const idParam = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const deleted = await TimetableService.deleteTimetableSlot(idParam);
      return sendSuccess(res, deleted, 'Timetable slot removed successfully');
    } catch (err: any) {
      return sendError(res, err.message, 400);
    }
  }
}
