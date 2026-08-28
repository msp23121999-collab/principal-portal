import { TimetableRepository } from '../repositories/timetable.repository';

export class TimetableService {
  static async getSectionTimetable(sectionId: string) {
    if (!sectionId) throw new Error('Section ID is required');
    return await TimetableRepository.findBySection(sectionId);
  }

  static async getFacultyTimetable(facultyId: string) {
    if (!facultyId) throw new Error('Faculty ID is required');
    return await TimetableRepository.findByFaculty(facultyId);
  }

  static async createTimetableSlot(data: any) {
    if (!data.faculty_id || !data.subject_id || !data.class_section_id || !data.day_of_week || !data.period) {
      throw new Error('Missing required timetable slot parameters');
    }
    return await TimetableRepository.createEntry(data);
  }

  static async deleteTimetableSlot(id: string) {
    if (!id) throw new Error('Slot ID is required');
    return await TimetableRepository.deleteEntry(id);
  }
}
