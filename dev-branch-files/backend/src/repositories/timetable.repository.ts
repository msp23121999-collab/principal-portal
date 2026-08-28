import { pool } from '../config/database';

export class TimetableRepository {
  static async findBySection(classSectionId: string) {
    const result = await pool.query(
      `SELECT t.*, s.name as subject_name, s.subject_code, f.full_name as faculty_name 
       FROM public.timetables t
       LEFT JOIN public.subjects s ON t.subject_id = s.id
       LEFT JOIN public.faculties f ON t.faculty_id = f.id
       WHERE t.class_section_id = $1
       ORDER BY t.day_of_week, t.period`,
      [classSectionId]
    );
    return result.rows;
  }

  static async findByFaculty(facultyId: string) {
    const result = await pool.query(
      `SELECT t.*, s.name as subject_name, s.subject_code, cs.name as section_name 
       FROM public.timetables t
       LEFT JOIN public.subjects s ON t.subject_id = s.id
       LEFT JOIN public.class_sections cs ON t.class_section_id = cs.id
       WHERE t.faculty_id = $1
       ORDER BY t.day_of_week, t.period`,
      [facultyId]
    );
    return result.rows;
  }

  static async createEntry(data: {
    faculty_id: string;
    subject_id: string;
    class_section_id: string;
    day_of_week: string;
    period: string;
    room_no?: string;
    building?: string;
  }) {
    const result = await pool.query(
      `INSERT INTO public.timetables (faculty_id, subject_id, class_section_id, day_of_week, period, room_no, building)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [data.faculty_id, data.subject_id, data.class_section_id, data.day_of_week, data.period, data.room_no || null, data.building || null]
    );
    return result.rows[0];
  }

  static async deleteEntry(id: string) {
    const result = await pool.query(
      `DELETE FROM public.timetables WHERE id = $1 RETURNING *`,
      [id]
    );
    return result.rows[0];
  }
}
