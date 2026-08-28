import { Router } from 'express';
import { StudentsController } from '../../controllers/students.controller';
import { authenticateJwt } from '../../middleware/auth.middleware';

export const studentsRouter = Router();

studentsRouter.use(authenticateJwt);

studentsRouter.get('/', StudentsController.getAllStudents);
studentsRouter.get('/:id', StudentsController.getStudentById);
