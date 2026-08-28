class Education {
  const Education({
    required this.degree,
    required this.institution,
    required this.yearCompleted,
  });

  final String degree;
  final String institution;
  final int yearCompleted;
}

class ResearchPaper {
  const ResearchPaper({
    required this.title,
    required this.journalOrConference,
    required this.year,
    this.doiOrLink,
  });

  final String title;
  final String journalOrConference;
  final int year;
  final String? doiOrLink;
}

class Award {
  const Award({
    required this.title,
    required this.issuedBy,
    required this.year,
  });

  final String title;
  final String issuedBy;
  final int year;
}

class DocumentItem {
  const DocumentItem({
    required this.name,
    required this.type,
    required this.uploadedAt,
  });

  final String name;
  final String type;
  final DateTime uploadedAt;
}

class OfficeDetails {
  const OfficeDetails({
    required this.cabinLocation,
    required this.officeHours,
    required this.extensionNumber,
  });

  final String cabinLocation;
  final String officeHours;
  final String extensionNumber;
}

class ContactInfo {
  const ContactInfo({
    required this.email,
    required this.phone,
    required this.address,
  });

  final String email;
  final String phone;
  final String address;
}

/// A single administrative responsibility/committee membership shown on the
/// Responsibilities tab.
class Responsibility {
  const Responsibility({
    required this.title,
    required this.description,
    required this.since,
  });

  final String title;
  final String description;
  final int since;
}

class PrincipalProfile {
  const PrincipalProfile({
    required this.name,
    required this.designation,
    required this.employeeId,
    required this.dateOfBirth,
    required this.gender,
    required this.experienceYears,
    required this.hodExperienceYears,
    required this.education,
    required this.researchPapers,
    required this.awards,
    required this.documents,
    required this.responsibilities,
    required this.officeDetails,
    required this.contactInfo,
  });

  final String name;
  final String designation;
  final String employeeId;
  final DateTime dateOfBirth;
  final String gender;
  final int experienceYears;
  final int hodExperienceYears;
  final List<Education> education;
  final List<ResearchPaper> researchPapers;
  final List<Award> awards;
  final List<DocumentItem> documents;
  final List<Responsibility> responsibilities;
  final OfficeDetails officeDetails;
  final ContactInfo contactInfo;
}
