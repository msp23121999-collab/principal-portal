import { Router } from 'express';
import { TimetableController } from '../../controllers/timetable.controller';
import { authenticateJwt } from '../../middleware/auth.middleware';
import { requireRole } from '../../middleware/role.middleware';
import { UserRole } from '../../constants/roles';

export const timetableRouter = Router();

timetableRouter.use(authenticateJwt);

timetableRouter.get('/section/:sectionId', TimetableController.getSectionTimetable);
timetableRouter.get('/faculty/:facultyId', TimetableController.getFacultyTimetable);
timetableRouter.post('/', requireRole(UserRole.HOD, UserRole.ADMIN, UserRole.SUPER_ADMIN), TimetableController.createSlot);
timetableRouter.delete('/:id', requireRole(UserRole.HOD, UserRole.ADMIN, UserRole.SUPER_ADMIN), TimetableController.deleteSlot);
