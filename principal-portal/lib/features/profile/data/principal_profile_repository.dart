import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/principal_profile.dart';

/// Reads the Principal's profile from `principal`.
///
/// The profile and its five child lists — degrees, papers, awards, documents,
/// responsibilities — are one row plus five child tables, fetched in a single
/// embedded select.
///
/// The profile is securely keyed to the authenticated Supabase user ID, meaning
/// RLS policies ensure the user only accesses their own profile.
class PrincipalProfileRepository extends Repository {
  const PrincipalProfileRepository();

  Future<Sourced<PrincipalProfile>> fetch() {
    return load<PrincipalProfile>(
      debugLabel: 'principal.principal_profiles',
      fromSupabase: () async {

        final row = await ApiClient.schema(DbSchema.principal)
            .from('principal_profiles')
            .select(
              '*, '
              'profile_education(degree, institution, year_completed, display_order), '
              'profile_research_papers(title, journal_or_conference, year, doi_or_link, display_order), '
              'profile_awards(title, issued_by, year, display_order), '
              'profile_documents(name, doc_type, uploaded_at, display_order), '
              'profile_responsibilities(title, description, since_year, display_order)',
            )
            .limit(1)
            .maybeSingle();

        // A missing profile is a real state — nobody has been recorded as
        // Principal yet — and the screen should say so rather than surface the
        // database driver's own error text. Nothing is invented to fill it.
        if (row == null) {
          throw StateError(
            'No Principal profile has been recorded yet. '
            'The backend must provision a canonical Principal identity mapping.',
          );
        }

        return _toProfile(Map<String, dynamic>.from(row));
      },
    );
  }

  /// Child rows arrive unordered; `display_order` is what makes them a list.
  List<Map<String, dynamic>> _children(Map<String, dynamic> row, String table) {
    final raw = row[table];
    if (raw is! List) return const [];

    final items =
        [for (final entry in raw) Map<String, dynamic>.from(entry as Map)]
          ..sort(
            (a, b) => a
                .intOr('display_order', 0)
                .compareTo(b.intOr('display_order', 0)),
          );
    return items;
  }

  PrincipalProfile _toProfile(Map<String, dynamic> row) {
    return PrincipalProfile(
      name: row.strOr('name', ''),
      designation: row.strOr('designation', 'Principal'),
      employeeId: row.strOr('employee_id', '—'),
      dateOfBirth: row.dateOr('date_of_birth', DateTime(1970)),
      gender: row.strOr('gender', '—'),
      experienceYears: row.intOr('experience_years', 0),
      hodExperienceYears: row.intOr('hod_experience_years', 0),
      education: [
        for (final e in _children(row, 'profile_education'))
          Education(
            degree: e.strOr('degree', ''),
            institution: e.strOr('institution', ''),
            yearCompleted: e.intOr('year_completed', 0),
          ),
      ],
      researchPapers: [
        for (final p in _children(row, 'profile_research_papers'))
          ResearchPaper(
            title: p.strOr('title', ''),
            journalOrConference: p.strOr('journal_or_conference', ''),
            year: p.intOr('year', 0),
            doiOrLink: p.str('doi_or_link'),
          ),
      ],
      awards: [
        for (final a in _children(row, 'profile_awards'))
          Award(
            title: a.strOr('title', ''),
            issuedBy: a.strOr('issued_by', ''),
            year: a.intOr('year', 0),
          ),
      ],
      documents: [
        for (final d in _children(row, 'profile_documents'))
          DocumentItem(
            name: d.strOr('name', ''),
            type: d.strOr('doc_type', ''),
            uploadedAt: d.dateOr('uploaded_at', DateTime.now()),
          ),
      ],
      responsibilities: [
        for (final r in _children(row, 'profile_responsibilities'))
          Responsibility(
            title: r.strOr('title', ''),
            description: r.strOr('description', ''),
            since: r.intOr('since_year', 0),
          ),
      ],
      officeDetails: OfficeDetails(
        cabinLocation: row.strOr('cabin_location', '—'),
        officeHours: row.strOr('office_hours', '—'),
        extensionNumber: row.strOr('extension_number', '—'),
      ),
      contactInfo: ContactInfo(
        email: row.strOr('email', '—'),
        phone: row.strOr('phone', '—'),
        address: row.strOr('address', '—'),
      ),
    );
  }
}
