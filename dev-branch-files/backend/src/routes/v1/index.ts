import { Router } from 'express';
import { authRouter } from './auth.routes';
import { timetableRouter } from './timetable.routes';
import { studentsRouter } from './students.routes';
import { facultyRouter } from './faculty.routes';
import { departmentsRouter } from './departments.routes';
import { attendanceRouter } from './attendance.routes';
import { marksRouter } from './marks.routes';
import { leaveRouter } from './leave.routes';

export const v1Router = Router();

v1Router.use('/auth', authRouter);
v1Router.use('/timetables', timetableRouter);
v1Router.use('/students', studentsRouter);
v1Router.use('/faculty', facultyRouter);
v1Router.use('/departments', departmentsRouter);
v1Router.use('/attendance', attendanceRouter);
v1Router.use('/marks', marksRouter);
v1Router.use('/leave', leaveRouter);
