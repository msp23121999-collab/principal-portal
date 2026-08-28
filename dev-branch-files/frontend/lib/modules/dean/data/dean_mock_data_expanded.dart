// Comprehensive expanded mock data for Dean Portal
// This file contains significantly more realistic institutional data
// Generated deterministically with Indian academic context

class DeanMockDataExpanded {
  // List of Indian first names
  static const List<String> firstNames = [
    'Aarav', 'Aditya', 'Amit', 'Anand', 'Aniruddh', 'Ankur', 'Anurag', 'Arjun', 'Aryan', 'Ashok',
    'Avishek', 'Bhavesh', 'Bhavna', 'Chandra', 'Chirag', 'Deepak', 'Devesh', 'Dhruv', 'Dileep', 'Dinesh',
    'Divyesh', 'Dushyant', 'Eklavya', 'Eshan', 'Farhan', 'Girish', 'Gopal', 'Govind', 'Gyan', 'Harsh',
    'Harshal', 'Harshit', 'Hemant', 'Hemendra', 'Himanshu', 'Hiren', 'Ish', 'Ismail', 'Jagjeet', 'Jaswant',
    'Javed', 'Jay', 'Jayant', 'Jayesh', 'Jayson', 'Jeevan', 'Jeetsing', 'Jeev', 'Jignesh', 'Joban',
    'Joydeep', 'Joyendra', 'Jugal', 'Jyoti', 'Kamlesh', 'Kannan', 'Karan', 'Karank', 'Karthik', 'Kashif',
    'Kavi', 'Kavin', 'Kavishankar', 'Kaylash', 'Keerti', 'Kesar', 'Ketan', 'Kevin', 'Keyur', 'Khan',
    'Kherva', 'Khilendra', 'Kinari', 'Kishan', 'Kishor', 'Kshitij', 'Kunal', 'Kundan', 'Kunsh', 'Kusum',
    'Kusumesh', 'Lakshmanan', 'Laxman', 'Lalit', 'Lalitesh', 'Laxminarayan', 'Lenny', 'Leonid', 'Lersh', 'Leshan',
    'Leshank', 'Leutkumar', 'Linesh', 'Lochan', 'Lokesh', 'Lokenath', 'Lovendra', 'Lovesh', 'Luv', 'Luv Kush',
    'Madhavan', 'Madhur', 'Madhureshan', 'Madhuri', 'Madhuwanshi', 'Madhusudan', 'Madhyan', 'Magan', 'Magendar', 'Magesh',
    'Mahantesh', 'Mahar', 'Mahendra', 'Mahesh', 'Maheshwari', 'Mahid', 'Mahidhar', 'Mahiendra', 'Mahindra', 'Mahir',
    'Mahjin', 'Mahmood', 'Mahmud', 'Mahraj', 'Mahendra', 'Mahesh', 'Mahipal', 'Mahir', 'Mahishasur', 'Mahit',
    'Mahjor', 'Mahjorin', 'Mahmudi', 'Mahmod', 'Mahnoor', 'Mahomet', 'Mahometh', 'Mahoning', 'Mahoor', 'Mahot'
  ];

  static const List<String> lastNames = [
    'Sharma', 'Singh', 'Kumar', 'Patel', 'Reddy', 'Rao', 'Nair', 'Iyer', 'Murugan', 'Verma',
    'Gupta', 'Yadav', 'Mishra', 'Pandey', 'Sinha', 'Dutta', 'Bhat', 'Jain', 'Pillai', 'Menon',
    'Srivastava', 'Trivedi', 'Chopra', 'Malhotra', 'Bhatnagar', 'Bhargava', 'Agarwal', 'Mittal', 'Mahajan', 'Sethi',
    'Kapoor', 'Bhaskar', 'Bhattacharya', 'Dey', 'Chatterjee', 'Mukherjee', 'Banerjee', 'Dasgupta', 'Sengupta', 'Ray',
    'Roy', 'Das', 'Dutta', 'Ghosh', 'Maity', 'Pal', 'Sen', 'Biswas', 'Sarkar', 'Seal',
    'Bose', 'Nath', 'Dastidar', 'Raghavan', 'Ravikumar', 'Raman', 'Ramakrishnan', 'Ramanathan', 'Ramesh', 'Rammohan',
    'Ramprasad', 'Ramachandran', 'Ramakumar', 'Ramaswamy', 'Ramendra', 'Ramdoss', 'Ramagopal', 'Rajesh', 'Rajendran', 'Rajesh',
    'Rajkumar', 'Rajendra', 'Rajesh', 'Rajiv', 'Rajkishor', 'Rajmohan', 'Rajsekar', 'Rajendra', 'Rajgopal', 'Rajesh',
    'Roshan', 'Roy', 'Ruchir', 'Rudra', 'Rudresh', 'Rupal', 'Rupak', 'Rupali', 'Rupen', 'Rushit',
    'Rushi', 'Rushikesh', 'Rushikumar', 'Rushil', 'Rushindra', 'Rushit', 'Ruslan', 'Rusli', 'Saatvik', 'Sachin'
  ];

  // Helper to generate deterministic CGPAs with realistic variation
  static double _generateCGPA(int studentId, int departmentId) {
    final base = 6.5 + ((studentId + departmentId) % 100) / 100 * 2.5;
    return double.parse(base.toStringAsFixed(2));
  }

  // Helper to generate realistic attendance
  static double _generateAttendance(int studentId) {
    final base = 75.0 + ((studentId * 7) % 25);
    return double.parse(base.toStringAsFixed(1));
  }

  // Helper to generate deterministic performance scores
  static double _generatePerformance(int facultyId) {
    final base = 75.0 + ((facultyId * 13) % 20);
    return double.parse(base.toStringAsFixed(1));
  }

  // Generate all students with realistic variation
  static List<Map<String, dynamic>> generateStudents() {
    final students = <Map<String, dynamic>>[];
    final deptList = [
      ('Computer Science & Engineering', 'CSE', 'B.E. CSE'),
      ('Information Technology', 'IT', 'B.Tech IT'),
      ('Artificial Intelligence & Data Science', 'AI & DS', 'B.Tech AI & DS'),
      ('Electronics & Communication Engineering', 'ECE', 'B.E. ECE'),
      ('Electrical & Electronics Engineering', 'EEE', 'B.E. EEE'),
      ('Mechanical Engineering', 'MECH', 'B.E. MECH'),
      ('Civil Engineering', 'CIVIL', 'B.E. CIVIL'),
      ('Cyber Security', 'CYSC', 'B.Tech CS'),
      ('Computer Science & Business Systems', 'CSBS', 'B.Tech CSBS'),
    ];

    int sid = 1;
    for (int deptIdx = 0; deptIdx < deptList.length; deptIdx++) {
      final (deptName, deptCode, prog) = deptList[deptIdx];
      // 50-100 students per department
      final studentCount = 50 + (deptIdx * 5) % 50;
      
      for (int i = 0; i < studentCount; i++) {
        final firstName = firstNames[(sid * 7) % firstNames.length];
        final lastName = lastNames[(sid * 11) % lastNames.length];
        final year = (sid % 4) + 1;
        final semester = (year * 2) - (sid % 2);

        students.add({
          'id': 'S${sid.toString().padLeft(4, '0')}',
          'reg_no': '${DateTime.now().year}$deptCode${sid.toString().padLeft(3, '0')}',
          'name': '$firstName $lastName',
          'department': deptName,
          'dept': deptCode,
          'programme': prog,
          'program': prog,
          'year': year,
          'semester': semester,
          'cgpa': _generateCGPA(sid, deptIdx),
          'attendance_percentage': _generateAttendance(sid),
        });
        sid++;
      }
    }
    return students;
  }

  // Generate all faculty with realistic variation
  static List<Map<String, dynamic>> generateFaculty() {
    final faculty = <Map<String, dynamic>>[];
    final deptList = [
      'Computer Science & Engineering',
      'Information Technology',
      'Artificial Intelligence & Data Science',
      'Electronics & Communication Engineering',
      'Electrical & Electronics Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Cyber Security',
      'Computer Science & Business Systems',
    ];

    final designations = ['Professor', 'Associate Professor', 'Assistant Professor', 'Senior Assistant Professor'];

    int fid = 1;
    for (int deptIdx = 0; deptIdx < deptList.length; deptIdx++) {
      final dept = deptList[deptIdx];
      final deptCode = ['CSE', 'IT', 'AI & DS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'CYSC', 'CSBS'][deptIdx];
      
      // 10-25 faculty per department
      final facultyCount = 10 + (deptIdx * 2) % 15;
      
      for (int i = 0; i < facultyCount; i++) {
        final firstName = firstNames[(fid * 13) % firstNames.length];
        final lastName = lastNames[(fid * 17) % lastNames.length];
        final experience = 2 + (fid % 25);
        final designation = designations[fid % designations.length];
        final rating = 3.8 + ((fid * 19) % 22) / 100;

        faculty.add({
          'id': 'F${fid.toString().padLeft(3, '0')}',
          'employee_id': 'EMP-${(1000 + fid).toString()}',
          'name': 'Dr. $firstName $lastName',
          'department': dept,
          'dept': deptCode,
          'designation': designation,
          'experience_years': experience,
          'rating': double.parse(rating.toStringAsFixed(1)),
          'avg_contact_hours': 14 + (fid % 8),
          'pass_rate': 82 + (fid % 18),
          'publications_count': 3 + (fid % 15),
          'research_projects': 1 + (fid % 4),
        });
        fid++;
      }
    }
    return faculty;
  }

  // Generate comprehensive courses
  static List<Map<String, dynamic>> generateCourses() {
    final courses = <Map<String, dynamic>>[];
    final courseBaseData = [
      // CSE courses
      (['CS2401', 'CS2402', 'CS2403', 'CS2404', 'CS2405', 'CS3401', 'CS3402', 'CS3403', 'CS4401', 'CS4402',
        'CS4403', 'CS4404', 'CS4405', 'CS4406', 'CS4407', 'CSL401', 'CSL402', 'CSL403'],
       'Computer Science & Engineering', 'CSE', 'B.E. CSE'),
      // IT courses
      (['IT2401', 'IT2402', 'IT2403', 'IT3401', 'IT3402', 'IT4401', 'IT4402', 'IT4403', 'IT4404', 'IT4405',
        'ITL401', 'ITL402', 'ITL403'],
       'Information Technology', 'IT', 'B.Tech IT'),
      // AI & DS courses
      (['AD2401', 'AD2402', 'AD3401', 'AD3402', 'AD4401', 'AD4402', 'AD4403', 'ADL401', 'ADL402'],
       'Artificial Intelligence & Data Science', 'AI & DS', 'B.Tech AI & DS'),
      // ECE courses
      (['EC2401', 'EC2402', 'EC2403', 'EC3401', 'EC3402', 'EC4401', 'EC4402', 'EC4403', 'ECL401', 'ECL402'],
       'Electronics & Communication Engineering', 'ECE', 'B.E. ECE'),
      // EEE courses
      (['EE2401', 'EE2402', 'EE3401', 'EE3402', 'EE4401', 'EE4402', 'EEL401', 'EEL402'],
       'Electrical & Electronics Engineering', 'EEE', 'B.E. EEE'),
      // MECH courses
      (['ME2401', 'ME2402', 'ME3401', 'ME3402', 'ME4401', 'ME4402', 'MEL401', 'MEL402'],
       'Mechanical Engineering', 'MECH', 'B.E. MECH'),
      // CIVIL courses
      (['CE2401', 'CE2402', 'CE3401', 'CE4401', 'CEL401'],
       'Civil Engineering', 'CIVIL', 'B.E. CIVIL'),
    ];

    const courseNames = {
      'CS': ['Data Structures', 'Object Oriented Programming', 'Database Management', 'Web Development', 'Algorithms',
             'Operating Systems', 'Computer Networks', 'Software Engineering', 'AI & ML', 'Data Mining',
             'Cloud Computing', 'Cybersecurity', 'Mobile Development', 'Compiler Design', 'Advanced Databases'],
      'IT': ['Web Technology', 'IT Infrastructure', 'Database Design', 'Network Administration', 'IT Security',
             'Cloud Services', 'IT Project Management', 'IT Governance', 'IT Audit', 'IT Compliance'],
      'AD': ['Machine Learning', 'Deep Learning', 'Data Analytics', 'Neural Networks', 'NLP', 'Computer Vision',
             'Big Data Analytics', 'Statistical Analysis', 'Python for Data Science', 'Data Visualization'],
      'EC': ['Digital Electronics', 'Analog Circuits', 'Microprocessors', 'Power Systems', 'Control Systems',
             'Signal Processing', 'Embedded Systems', 'VLSI Design', 'Microcontrollers', 'Communication Systems'],
      'EE': ['Power Electronics', 'Electrical Machines', 'Power Systems', 'Control Systems', 'Drives & Automation',
             'High Voltage Engineering', 'Electrical Safety', 'Power Generation', 'Power Distribution', 'Substation Design'],
      'ME': ['Thermodynamics', 'Heat Transfer', 'Fluid Mechanics', 'Mechanics of Materials', 'Machine Design',
             'Manufacturing Engineering', 'CAD & CAM', 'Mechanical Vibrations', 'Automation', 'Robotics'],
      'CE': ['Surveying', 'Soil Mechanics', 'Structural Analysis', 'RCC Design', 'Steel Design',
             'Hydraulics', 'Environmental Engineering', 'Construction Management'],
    };

    int courseId = 1;
    for (final (codes, deptName, deptCode, program) in courseBaseData) {
      // Extract prefix from actual course codes (e.g., 'CS' from 'CS2401', 'AD' from 'AD2401')
      // Don't try to derive from department code which may have different format
      String coursePrefix = '';
      if (codes.isNotEmpty) {
        final firstCode = codes.first;
        for (int i = 0; i < firstCode.length; i++) {
          final char = firstCode[i];
          final codeUnit = char.codeUnitAt(0);
          if (codeUnit >= 48 && codeUnit <= 57) break;
          coursePrefix += char;
        }
      }
      final nameList = courseNames[coursePrefix] ?? [];
      
      for (int i = 0; i < codes.length; i++) {
        final code = codes[i];
        // Extract semester level: for normal courses code[2] is a digit (2,3,4)
        // For lab courses like CSL401, code[2] is 'L', so use code[3] instead
        final semesterDigitChar = code.contains('L') ? (code.length > 3 ? code[3] : '4') : code[2];
        final semesterLevel = int.tryParse(semesterDigitChar) ?? 2;
        final semester = (semesterLevel * 2) - 1 + (i % 2);
        final credits = code.contains('L') ? 1 : 3 + (i % 2);
        // Safety check: ensure nameList is not empty before using modulo
        final name = nameList.isNotEmpty ? nameList[i % nameList.length] : 'Course ${code.toUpperCase()}';

        courses.add({
          'id': 'CRS${courseId.toString().padLeft(4, '0')}',
          'course_code': code,
          'code': code,
          'course_title': name,
          'title': name,
          'department': deptName,
          'dept': deptCode,
          'programme': program,
          'program': program,
          'semester': 'Semester $semester',
          'type': code.contains('L') ? 'Lab' : 'Core',
          'credits': credits,
          'ltp': code.contains('L') ? '0-0-3' : '3-1-0',
          'status': 'ACTIVE',
          'bos_status': 'Approved',
          'academic_year': '2024-2025',
        });
        courseId++;
      }
    }
    return courses;
  }

  // Generate comprehensive examination schedule
  static List<Map<String, dynamic>> generateExams() {
    final exams = <Map<String, dynamic>>[];
    final examTypes = ['Internal Assessment', 'Model Examination', 'End Semester'];
    final courses = generateCourses();
    
    int examId = 1;
    for (final examType in examTypes) {
      final dayOffset = examType == 'Internal Assessment' ? 7 : examType == 'Model Examination' ? 21 : 45;
      
      for (int i = 0; i < courses.length; i += 3) {
        if (i < courses.length) {
          final course = courses[i];
          final date = DateTime.now().add(Duration(days: dayOffset + i));
          final status = ['Scheduled', 'Ongoing', 'Completed', 'Evaluation Pending', 'Results Published'][(examId % 5)];

          exams.add({
            'id': 'EXM${examId.toString().padLeft(4, '0')}',
            'exam_code': '${course['code']}-${examType.replaceAll(' ', '')}',
            'exam_name': '${examType} - ${course['course_title']}',
            'exam_type': examType,
            'course': course['course_title'],
            'course_code': course['code'],
            'department': course['dept'],
            'dept': course['dept'],
            'semester': course['semester'],
            'date': date.toIso8601String().split('T').first,
            'start_time': '${9 + (examId % 3)}:00',
            'end_time': '${12 + (examId % 3)}:00',
            'room': 'Hall ${(examId % 10) + 1}',
            'student_count': 30 + (examId % 50),
            'status': status,
          });
          examId++;
        }
      }
    }
    return exams;
  }

  // Generate lesson plans
  static List<Map<String, dynamic>> generateLessonPlans() {
    final lessonPlans = <Map<String, dynamic>>[];
    final faculty = generateFaculty();
    final courses = generateCourses();
    
    int lpId = 1;
    for (int i = 0; i < courses.length && i < faculty.length * 2; i++) {
      final course = courses[i];
      final fac = faculty[i % faculty.length];
      if (fac['dept'] == course['dept']) {
        final completionPct = (lpId * 13) % 101;
        final status = completionPct == 100
            ? 'Completed'
            : completionPct >= 70
                ? 'On Track'
                : completionPct >= 40
                    ? 'In Progress'
                    : 'Delayed';

        lessonPlans.add({
          'id': 'LP${lpId.toString().padLeft(4, '0')}',
          'faculty': fac['name'],
          'faculty_id': fac['id'],
          'department': course['dept'],
          'course': course['course_title'],
          'course_code': course['code'],
          'semester': course['semester'],
          'planned_hours': 48,
          'completed_hours': (48 * completionPct ~/ 100),
          'coverage': completionPct / 100.0,
          'completion_percentage': completionPct,
          'units_completed': '${(5 * completionPct ~/ 100)}/5',
          'last_updated': DateTime.now().subtract(Duration(days: lpId % 10)).toIso8601String(),
          'status': status,
        });
        lpId++;
      }
    }
    return lessonPlans;
  }

  // Generate attendance records
  static List<Map<String, dynamic>> generateAttendance() {
    final attendance = <Map<String, dynamic>>[];
    final students = generateStudents();
    final courses = generateCourses();
    
    int attId = 1;
    for (int i = 0; i < students.length && i < 200; i++) {
      final student = students[i];
      final course = courses[i % courses.length];
      
      if (student['dept'] == course['dept']) {
        final totalClasses = 40 + (attId % 20);
        final attended = ((student['attendance_percentage'] as double) * totalClasses ~/ 100).toInt();
        final attPct = (attended * 100.0 / totalClasses);
        final status = attPct >= 85
            ? 'Excellent'
            : attPct >= 75
                ? 'Satisfactory'
                : attPct >= 65
                    ? 'Shortage'
                    : 'Critical';

        attendance.add({
          'id': 'ATT${attId.toString().padLeft(5, '0')}',
          'student_id': student['id'],
          'student_name': student['name'],
          'department': student['dept'],
          'course': course['code'],
          'course_name': course['course_title'],
          'semester': student['semester'],
          'total_classes': totalClasses,
          'attended': attended,
          'percentage': double.parse(attPct.toStringAsFixed(2)),
          'status': status,
          'academic_year': '2024-2025',
        });
        attId++;
      }
    }
    return attendance;
  }

  // Generate approvals
  static List<Map<String, dynamic>> generateApprovals() {
    final approvals = <Map<String, dynamic>>[];
    final faculty = generateFaculty();
    final types = ['HOD Leave', 'Faculty Profile Update', 'Course Allocation', 'OD Request', 
                   'Academic Permission', 'Research Approval', 'Event Approval', 'Budget Approval'];
    final statuses = ['PENDING', 'APPROVED', 'REJECTED'];

    for (int i = 0; i < 60; i++) {
      final fac = faculty[i % faculty.length];
      final type = types[i % types.length];
      final status = statuses[i % statuses.length];
      final days = 30 - (i % 30);

      approvals.add({
        'id': 'REQ-${(900 + i).toString()}',
        'display_id': 'REQ-${(900 + i).toString()}',
        'request_id': 'REQ-${(900 + i).toString()}',
        'type': type,
        'applicant_name': fac['name'],
        'applicant_id': fac['id'],
        'department': fac['dept'],
        'summary': _generateApprovalSummary(type, fac['name']),
        'status': status,
        'created_at': DateTime.now().subtract(Duration(days: days)).toIso8601String(),
      });
    }
    return approvals;
  }

  static String _generateApprovalSummary(String type, String name) {
    switch (type) {
      case 'HOD Leave':
        return 'Leave request for conference/seminar attendance';
      case 'Faculty Profile Update':
        return 'Update qualification and experience documentation';
      case 'Course Allocation':
        return 'New course allocation for current semester';
      case 'OD Request':
        return 'On-Duty request for academic/official work';
      case 'Research Approval':
        return 'Research project approval and fund allocation';
      case 'Event Approval':
        return 'Department event or seminar approval';
      case 'Budget Approval':
        return 'Budget allocation for department activities';
      default:
        return 'Academic approval request';
    }
  }

  // Generate notifications/circulars
  static List<Map<String, dynamic>> generateNotifications() {
    final notifications = <Map<String, dynamic>>[];
    final categories = ['Academic', 'Examination', 'Administration', 'Research', 'Accreditation', 'Events', 'Faculty', 'Student Affairs'];
    final priorities = ['Normal', 'Important', 'Urgent'];

    final notificationTemplates = [
      ('Academic Calendar Released', 'Academic Year 2024-2025 academic calendar has been released', 'Academic'),
      ('Semester Registration', 'Semester registration window is now open', 'Academic'),
      ('Examination Schedule', 'End semester examination schedule released', 'Examination'),
      ('Result Publication', 'Semester results are now published in the portal', 'Examination'),
      ('Faculty FDP Notification', 'Online FDP courses available for enrollment', 'Faculty'),
      ('Research Funding Opportunity', 'DST research funding opportunity for interested faculty', 'Research'),
      ('Accreditation Preparation', 'Accreditation visit scheduled, document submission deadline', 'Accreditation'),
      ('Workshop Announcement', 'Professional development workshop scheduled', 'Events'),
      ('Admission Notification', 'Admission process started for new batch', 'Administration'),
      ('Leave Policy Update', 'Updated leave policy effective from this semester', 'Administration'),
    ];

    int notId = 1;
    for (int i = 0; i < 80; i++) {
      final template = notificationTemplates[i % notificationTemplates.length];
      final category = categories[i % categories.length];
      final priority = priorities[i % priorities.length];
      final daysAgo = i % 60;

      notifications.add({
        'id': 'NOT${notId.toString().padLeft(5, '0')}',
        'title': template.$1,
        'description': template.$2,
        'category': category,
        'date': DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String(),
        'issued_by': 'Dean of Academics',
        'department': 'All Departments',
        'priority': priority,
        'read': i % 3 == 0, // Some marked as read
        'attachment': null,
        'status': 'Active',
      });
      notId++;
    }
    return notifications;
  }

  // Generate digital repository
  static List<Map<String, dynamic>> generateRepository() {
    final repository = <Map<String, dynamic>>[];
    final categories = ['Curriculum', 'Regulations', 'Question Bank', 'Accreditation', 
                       'Academic Policies', 'Circulars', 'Meeting Documents', 
                       'Research Documents', 'Examination Documents', 'Department Documents'];
    final depts = ['CSE', 'IT', 'AI & DS', 'ECE', 'EEE', 'MECH', 'CIVIL'];

    int repoId = 1;
    for (int i = 0; i < 100; i++) {
      final category = categories[i % categories.length];
      final dept = depts[i % depts.length];
      final filename = _generateRepositoryFilename(category, dept, i);

      repository.add({
        'id': 'DOC${repoId.toString().padLeft(5, '0')}',
        'file_name': filename,
        'file_path': '/documents/$category/$filename',
        'category': category,
        'department': dept,
        'file_type': 'pdf',
        'file_size': '${(100 + (repoId % 900))} KB',
        'uploaded_by': 'Admin',
        'upload_date': DateTime.now().subtract(Duration(days: repoId % 90)).toIso8601String(),
        'academic_year': '2024-2025',
        'description': 'Document for $category - $dept',
      });
      repoId++;
    }
    return repository;
  }

  static String _generateRepositoryFilename(String category, String dept, int id) {
    switch (category) {
      case 'Curriculum':
        return 'R2024_${dept}_Curriculum_Scheme_v${1 + (id % 3)}.pdf';
      case 'Regulations':
        return 'R2024_${dept}_Regulations_AY2024-25.pdf';
      case 'Question Bank':
        return 'AY2024_25_${dept}_QuestionBank_Sem${(id % 8) + 1}.pdf';
      case 'Accreditation':
        return 'NAAC_Criterion_${(id % 7) + 1}_${dept}_Evidence.pdf';
      case 'Meeting Documents':
        return 'BoS_${dept}_Minutes_${DateTime.now().year}_${(id % 12) + 1}.pdf';
      case 'Examination Documents':
        return '${dept}_EndSem_QP_Sem${(id % 8) + 1}_${DateTime.now().year}.pdf';
      default:
        return '${category.replaceAll(' ', '_')}_${dept}_Document_${id}.pdf';
    }
  }

  // Generate meetings/BOS
  static List<Map<String, dynamic>> generateMeetings() {
    final meetings = <Map<String, dynamic>>[];
    final types = [
      'Board of Studies',
      'Academic Council',
      'Department Meeting',
      'IQAC Meeting',
      'Dean Review',
      'Faculty Meeting',
      'Accreditation Meeting'
    ];
    final statuses = ['Scheduled', 'Completed', 'Minutes Pending', 'Minutes Published'];
    final depts = ['CSE', 'IT', 'AI & DS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'Institution'];
    final externalExperts = [
      'Dr. S. K. Vasudevan (IIT-M)',
      'Dr. R. Sundar (Anna Univ)',
      'Dr. A. Narayanan (NIT Trichy)',
      'Prof. M. S. Reddy (IISc)',
      'Dr. K. Vijaya (VIT)',
      'Dr. L. Natarajan (BITS Pilani)',
      'Anna Univ Nominees',
      'Industry Experts Panel'
    ];
    final approvedSchemes = [
      'R2024 Electives Approved',
      'R2024 Lab Courses Approved',
      'Autonomous Curriculum Revision',
      'Industry Internship Framework',
      'Research Collaboration MoU',
      'Outcome-Based Assessment Revision',
      'Academic Audit Action Plan',
      'Skill Enhancement Modules'
    ];

    int mtgId = 1;
    for (int i = 0; i < 60; i++) {
      final type = types[i % types.length];
      final status = statuses[i % statuses.length];
      final dept = depts[i % depts.length];
      final date = DateTime.now().add(Duration(days: (i % 36) - 18));
      final titleRef = type == 'Academic Council' ? 'AC-${(2025 + (i ~/ 5)).toString()}' : 'BOS-${(2025 + (i ~/ 4)).toString()}';
      final expert = externalExperts[i % externalExperts.length];
      final scheme = approvedSchemes[i % approvedSchemes.length];
      final minuteFile = 'MoM_${dept}_${type.replaceAll(' ', '_')}_${(i + 1).toString().padLeft(2, '0')}.pdf';

      meetings.add({
        'id': 'MTG${mtgId.toString().padLeft(4, '0')}',
        'meeting_id': '$titleRef-${(i + 1).toString().padLeft(2, '0')}',
        'meeting_type': type,
        'title': '$titleRef-${(i + 1).toString().padLeft(2, '0')} ($type)',
        'department': dept,
        'board': dept == 'Institution' ? 'Institutional Academic Council' : '$dept Board',
        'date': date.toIso8601String().split('T').first,
        'time': '${10 + (mtgId % 8)}:00',
        'venue': 'Conference Hall ${(mtgId % 5) + 1}',
        'chairperson': 'Dr. R. K. Sharma',
        'external_experts': expert,
        'approved_scheme': scheme,
        'participants': 5 + (mtgId % 15),
        'agenda': 'Review and discuss $type items',
        'status': status,
        'minutes_available': status == 'Minutes Published' || status == 'Minutes Pending',
        'minutes_file': minuteFile,
      });
      mtgId++;
    }
    return meetings;
  }

  // Generate accreditation documents
  static List<Map<String, dynamic>> generateAccreditation() {
    final accreditation = <Map<String, dynamic>>[];
    final criteria = [
      ('Crit 1.1', 'Curricular Aspects', 'Academic Cell'),
      ('Crit 1.2', 'Teaching-Learning Process', 'Academic Cell'),
      ('Crit 2.1', 'Student Support Services', 'Dean Office'),
      ('Crit 2.2', 'Student Performance & Learning Outcomes', 'Dean Office'),
      ('Crit 3.1', 'Research & Development', 'Research Cell'),
      ('Crit 3.2', 'Research Collaboration', 'Research Cell'),
      ('Crit 4.1', 'Physical Infrastructure', 'Admin'),
      ('Crit 4.2', 'Learning Resources', 'Library'),
      ('Crit 5.1', 'Student Diversity & Inclusion', 'Student Affairs'),
      ('Crit 5.2', 'Placement & Employability', 'Placement Cell'),
      ('Crit 6.1', 'Governance & Administration', 'Admin'),
      ('Crit 6.2', 'Financial Management', 'Finance'),
      ('Crit 7.1', 'Institutional Values & Social Responsibility', 'Admin'),
      ('Crit 7.2', 'Best Practices', 'Dean Office'),
    ];

    int accId = 1;
    for (int i = 0; i < 70; i++) {
      final crit = criteria[i % criteria.length];
      final status = ['Verified', 'Pending Verification', 'Rejected', 'Under Review'][(accId % 4)];

      accreditation.add({
        'id': 'ACC${accId.toString().padLeft(4, '0')}',
        'criterion': crit.$1,
        'description': crit.$2,
        'responsible_department': crit.$3,
        'submitted_files': '${10 + (accId % 50)} Files',
        'audit_status': status,
        'last_updated': DateTime.now().subtract(Duration(days: accId % 30)).toIso8601String(),
        'responsible_person': 'Dean of Academics',
      });
      accId++;
    }
    return accreditation;
  }

  // Generate research projects
  static List<Map<String, dynamic>> generateResearchProjects() {
    final projects = <Map<String, dynamic>>[];
    final facultyList = generateFaculty().take(50).toList();
    final fundingAgencies = ['DST', 'AICTE', 'SERB', 'CSIR', 'DBT', 'UGC', 'ICMR', 'ISRO'];
    final statuses = ['Active', 'Completed', 'Proposal Submitted', 'Under Review', 'Funded', 'Closed'];

    int projId = 1;
    for (int i = 0; i < 80; i++) {
      final fac = facultyList[i % facultyList.length];
      final agency = fundingAgencies[i % fundingAgencies.length];
      final status = statuses[i % statuses.length];
      final amount = 500000 + (projId * 17) % 1500000;

      projects.add({
        'id': 'PROJ${projId.toString().padLeft(4, '0')}',
        'title': _generateProjectTitle(i, fac['dept']),
        'pi_name': fac['name'],
        'pi_id': fac['id'],
        'department': fac['department'],
        'dept': fac['dept'],
        'funding_agency': agency,
        'grant_amount': amount,
        'amount': amount,
        'start_date': DateTime.now().subtract(Duration(days: 365 + (projId % 730))).toIso8601String(),
        'end_date': DateTime.now().add(Duration(days: 180 + (projId % 365))).toIso8601String(),
        'status': status,
        'publications': 2 + (projId % 8),
        'patents': (projId % 3),
        'collaborators': 1 + (projId % 5),
      });
      projId++;
    }
    return projects;
  }

  static String _generateProjectTitle(int id, String dept) {
    final titles = [
      'AI-based Optimization', 'IoT Applications', 'Machine Learning Models', 
      'Data Analytics Platform', 'Smart Systems Design', 'Embedded Solutions',
      'Cloud Computing Architecture', 'Cyber Security Framework', 'Autonomous Systems',
      'Renewable Energy Systems', 'Sustainable Manufacturing', 'Structural Analysis',
    ];
    return '${titles[id % titles.length]} for $dept';
  }
}
