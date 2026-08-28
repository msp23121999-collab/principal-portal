import '../models/principal_profile.dart';

/// Seed profile for the signed-in Principal.
class PrincipalProfileMockData {
  PrincipalProfileMockData._();

  static PrincipalProfile profile() => PrincipalProfile(
    name: 'Dr. S. Venkataraman',
    designation: 'Principal',
    employeeId: 'EMP-PRIN-001',
    dateOfBirth: DateTime(1968, 4, 12),
    gender: 'Male',
    experienceYears: 28,
    hodExperienceYears: 6,
    education: const [
      Education(
        degree: 'Ph.D. in Computer Science & Engineering',
        institution: 'Anna University',
        yearCompleted: 2004,
      ),
      Education(
        degree: 'M.E. in Computer Science & Engineering',
        institution: 'PSG College of Technology',
        yearCompleted: 1996,
      ),
      Education(
        degree: 'B.E. in Electronics & Communication Engineering',
        institution: 'Government College of Engineering, Salem',
        yearCompleted: 1992,
      ),
    ],
    researchPapers: const [
      ResearchPaper(
        title: 'Adaptive Learning Analytics in Engineering Education',
        journalOrConference: 'IEEE Transactions on Education',
        year: 2023,
        doiOrLink: '10.1109/TE.2023.001',
      ),
      ResearchPaper(
        title: 'A Framework for Outcome-Based Curriculum Design',
        journalOrConference: 'International Journal of Engineering Pedagogy',
        year: 2021,
      ),
      ResearchPaper(
        title: 'Energy-Efficient Scheduling in Campus IoT Networks',
        journalOrConference: 'Springer Wireless Networks',
        year: 2019,
        doiOrLink: '10.1007/s11276-019-xxxx',
      ),
      ResearchPaper(
        title: 'Machine Learning Approaches to Student Performance Prediction',
        journalOrConference: 'Elsevier Computers & Education',
        year: 2017,
      ),
    ],
    awards: const [
      Award(
        title: 'Best Principal Award — Tamil Nadu Technical Education',
        issuedBy: 'Directorate of Technical Education',
        year: 2024,
      ),
      Award(
        title: 'Outstanding Contribution to Engineering Education',
        issuedBy: 'ISTE National Council',
        year: 2020,
      ),
      Award(
        title: 'Distinguished Educator Award',
        issuedBy: 'Anna University',
        year: 2015,
      ),
    ],
    documents: [
      DocumentItem(
        name: 'Ph.D. Degree Certificate',
        type: 'PDF',
        uploadedAt: DateTime(2024, 1, 10),
      ),
      DocumentItem(
        name: 'AICTE Approval Letter 2026-27',
        type: 'PDF',
        uploadedAt: DateTime(2026, 3, 4),
      ),
      DocumentItem(
        name: 'Faculty Appointment Order',
        type: 'PDF',
        uploadedAt: DateTime(2023, 6, 18),
      ),
      DocumentItem(
        name: 'NAAC Peer Team Report',
        type: 'DOCX',
        uploadedAt: DateTime(2025, 11, 22),
      ),
      DocumentItem(
        name: 'Experience Certificate — HOD Tenure',
        type: 'PDF',
        uploadedAt: DateTime(2022, 8, 30),
      ),
    ],
    responsibilities: const [
      Responsibility(
        title: 'Chairperson, Academic Council',
        description:
            'Presides over curriculum approval and academic policy decisions.',
        since: 2023,
      ),
      Responsibility(
        title: 'Member, Governing Body',
        description: 'Institutional governance and strategic planning.',
        since: 2023,
      ),
      Responsibility(
        title: 'Chief Coordinator, NAAC Accreditation',
        description:
            'Oversees institutional quality assurance and NAAC cycle preparation.',
        since: 2024,
      ),
      Responsibility(
        title: 'Chairperson, Grievance Redressal Committee',
        description: 'Handles escalated student and staff grievances.',
        since: 2023,
      ),
    ],
    officeDetails: const OfficeDetails(
      cabinLocation: 'Admin Block, Ground Floor, Room 101',
      officeHours: 'Mon–Sat, 9:30 AM – 5:00 PM',
      extensionNumber: '+91 4288 274 741 (Ext. 101)',
    ),
    contactInfo: const ContactInfo(
      email: 'principal@ksrce.ac.in',
      phone: '+91 98765 12340',
      address:
          'KSR College of Engineering, Tiruchengode, Namakkal, Tamil Nadu 637215',
    ),
  );
}
